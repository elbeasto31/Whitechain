// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {ItemNFT721} from "./ItemNFT721.sol";
import {MagicToken} from "./MagicToken.sol";

contract Marketplace is AccessControl {
    struct Listing {
        address seller;
        uint256 price;
        bool active;
    }

    ItemNFT721 public items;
    MagicToken public magic;

    mapping(uint256 => Listing) public listings;

    constructor(ItemNFT721 _items, MagicToken _magic) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        items = _items;
        magic = _magic;
    }

    function list(uint256 tokenId, uint256 price) external {
        require(items.ownerOf(tokenId) == msg.sender, "owner");
        require(price > 0, "price");
        listings[tokenId] = Listing(msg.sender, price, true);
    }

    function delist(uint256 tokenId) external {
        Listing storage l = listings[tokenId];
        require(l.active, "inactive");
        require(l.seller == msg.sender, "seller");
        delete listings[tokenId];
    }

    function purchase(uint256 tokenId) external {
        Listing storage l = listings[tokenId];
        require(l.active, "inactive");
        require(items.ownerOf(tokenId) == l.seller, "moved");

        items.burn(tokenId);

        l.active = false;
        magic.mint(l.seller, l.price);
        delete listings[tokenId];
    }
}
