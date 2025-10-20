// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";

import {ResourceNFT1155} from "../src/ResourceNFT1155.sol";
import {ItemNFT721} from "../src/ItemNFT721.sol";
import {MagicToken} from "../src/MagicToken.sol";
import {CraftingSearch} from "../src/CraftingSearch.sol";
import {Marketplace} from "../src/Marketplace.sol";

contract TemplateTest is Test {
    ResourceNFT1155 res;
    ItemNFT721 items;
    MagicToken magic;
    CraftingSearch cs;
    Marketplace mkt;

    address admin = address(0xA11CE);
    address seller = address(0xB0B);
    address buyer = address(0xC0C);

    function setUp() public {
        vm.startPrank(admin);
        res = new ResourceNFT1155("Resources", "RES", "ipfs://resources/{id}.json");
        items = new ItemNFT721("ipfs://items/");
        magic = new MagicToken(admin);
        cs = new CraftingSearch(res, items);
        mkt = new Marketplace(items, magic);

        res.grantRole(res.MINTER_ROLE(), address(cs));
        res.grantRole(res.BURNER_ROLE(), address(cs));
        items.grantRole(items.MINTER_ROLE(), address(cs));
        items.grantRole(items.BURNER_ROLE(), address(mkt));
        magic.grantRole(magic.MARKET_ROLE(), address(mkt));
        vm.stopPrank();
    }

    function test_deployed_and_roles_wired() public {
        assertTrue(address(res) != address(0));
        assertTrue(address(items) != address(0));
        assertTrue(address(magic) != address(0));
        assertTrue(address(cs) != address(0));
        assertTrue(address(mkt) != address(0));
        assertTrue(res.hasRole(res.MINTER_ROLE(), address(cs)));
        assertTrue(res.hasRole(res.BURNER_ROLE(), address(cs)));
        assertTrue(items.hasRole(items.MINTER_ROLE(), address(cs)));
        assertTrue(items.hasRole(items.BURNER_ROLE(), address(mkt)));
        assertTrue(magic.hasRole(magic.MARKET_ROLE(), address(mkt)));
    }

    function test_search_cooldown_and_three_mints() public {
        vm.prank(seller);
        cs.search();
        uint256 total = 0;
        for (uint256 i = 1; i <= 6; i++) {
            total += res.balanceOf(seller, i);
        }
        assertEq(total, 3);
        vm.prank(seller);
        vm.expectRevert();
        cs.search();
        vm.warp(block.timestamp + 61);
        vm.prank(seller);
        cs.search();
        uint256 total2 = 0;
        for (uint256 i2 = 1; i2 <= 6; i2++) {
            total2 += res.balanceOf(seller, i2);
        }
        assertEq(total2, 6);
    }

    function test_craft_saber_burns_resources_and_mints_item() public {
        vm.startPrank(admin);
        res.grantRole(res.MINTER_ROLE(), address(this));
        vm.stopPrank();

        res.mint(seller, 2, 3);
        res.mint(seller, 1, 1);
        res.mint(seller, 4, 1);

        vm.prank(seller);
        cs.craft(1);

        assertEq(items.ownerOf(1), seller);
        assertEq(res.balanceOf(seller, 2), 0);
        assertEq(res.balanceOf(seller, 1), 0);
        assertEq(res.balanceOf(seller, 4), 0);
    }

    function test_craft_staff_burns_resources_and_mints_item() public {
        vm.startPrank(admin);
        res.grantRole(res.MINTER_ROLE(), address(this));
        vm.stopPrank();

        res.mint(seller, 1, 2);
        res.mint(seller, 3, 1);
        res.mint(seller, 6, 1);

        vm.prank(seller);
        cs.craft(2);

        assertEq(items.ownerOf(1), seller);
        assertEq(res.balanceOf(seller, 1), 0);
        assertEq(res.balanceOf(seller, 3), 0);
        assertEq(res.balanceOf(seller, 6), 0);
    }

    function test_marketplace_list_and_purchase_burns_item_and_mints_magic() public {
        vm.startPrank(admin);
        res.grantRole(res.MINTER_ROLE(), address(this));
        vm.stopPrank();

        res.mint(seller, 2, 3);
        res.mint(seller, 1, 1);
        res.mint(seller, 4, 1);

        vm.prank(seller);
        cs.craft(1);

        uint256 tokenId = 1;
        uint256 price = 1_000 ether;

        vm.prank(seller);
        items.approve(address(mkt), tokenId);

        vm.prank(seller);
        mkt.list(tokenId, price);

        vm.prank(buyer);
        mkt.purchase(tokenId);

        vm.expectRevert();
        items.ownerOf(tokenId);

        assertEq(magic.balanceOf(seller), price);
        assertEq(magic.balanceOf(buyer), 0);
    }

    function test_marketplace_delist() public {
        vm.startPrank(admin);
        res.grantRole(res.MINTER_ROLE(), address(this));
        vm.stopPrank();

        res.mint(seller, 2, 3);
        res.mint(seller, 1, 1);
        res.mint(seller, 4, 1);

        vm.prank(seller);
        cs.craft(1);

        uint256 tokenId = 1;
        uint256 price = 500 ether;

        vm.prank(seller);
        items.approve(address(mkt), tokenId);

        vm.prank(seller);
        mkt.list(tokenId, price);

        vm.prank(seller);
        mkt.delist(tokenId);

        vm.prank(buyer);
        vm.expectRevert();
        mkt.purchase(tokenId);
    }
}
