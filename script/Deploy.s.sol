// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "forge-std/console2.sol";

import {ResourceNFT1155} from "../src/ResourceNFT1155.sol";
import {ItemNFT721} from "../src/ItemNFT721.sol";
import {MagicToken} from "../src/MagicToken.sol";
import {CraftingSearch} from "../src/CraftingSearch.sol";
import {Marketplace} from "../src/Marketplace.sol";

contract Deploy is Script {
    function run() external {
        uint256 pk = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(pk);

        address admin = vm.addr(pk);

        ResourceNFT1155 res = new ResourceNFT1155("Resources", "RES", "ipfs://resources/{id}.json");
        ItemNFT721 items = new ItemNFT721("ipfs://items/");
        MagicToken magic = new MagicToken(admin);
        CraftingSearch cs = new CraftingSearch(res, items);
        Marketplace mkt = new Marketplace(items, magic);

        res.grantRole(res.MINTER_ROLE(), address(cs));
        res.grantRole(res.BURNER_ROLE(), address(cs));
        items.grantRole(items.MINTER_ROLE(), address(cs));
        items.grantRole(items.BURNER_ROLE(), address(mkt));
        magic.grantRole(magic.MARKET_ROLE(), address(mkt));

        vm.stopBroadcast();

        console2.log("ResourceNFT1155:", address(res));
        console2.log("ItemNFT721     :", address(items));
        console2.log("MagicToken     :", address(magic));
        console2.log("CraftingSearch :", address(cs));
        console2.log("Marketplace    :", address(mkt));
        console2.log("Admin          :", admin);
    }
}
