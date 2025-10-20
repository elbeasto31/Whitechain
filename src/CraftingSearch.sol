// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {ResourceNFT1155} from "./ResourceNFT1155.sol";
import {ItemNFT721} from "./ItemNFT721.sol";

contract CraftingSearch is AccessControl {
    ResourceNFT1155 public resources;
    ItemNFT721 public items;

    uint256 public constant COOLDOWN = 60;

    uint256 public constant WOOD = 1;
    uint256 public constant IRON = 2;
    uint256 public constant GOLD = 3;
    uint256 public constant LEATHER = 4;
    uint256 public constant STONE = 5;
    uint256 public constant DIAMOND = 6;

    uint8 public constant ITEM_SABER = 1;
    uint8 public constant ITEM_STAFF = 2;
    uint8 public constant ITEM_ARMOR = 3;
    uint8 public constant ITEM_BRACELET = 4;

    mapping(address => uint256) public lastSearchAt;

    mapping(uint8 => uint256[]) private recipeIds;
    mapping(uint8 => uint256[]) private recipeAmts;

    constructor(ResourceNFT1155 _resources, ItemNFT721 _items) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        resources = _resources;
        items = _items;

        recipeIds[ITEM_SABER] = [IRON, WOOD, LEATHER];
        recipeAmts[ITEM_SABER] = [3, 1, 1];

        recipeIds[ITEM_STAFF] = [WOOD, GOLD, DIAMOND];
        recipeAmts[ITEM_STAFF] = [2, 1, 1];

        recipeIds[ITEM_ARMOR] = [LEATHER, IRON, GOLD];
        recipeAmts[ITEM_ARMOR] = [4, 2, 1];

        recipeIds[ITEM_BRACELET] = [IRON, GOLD, DIAMOND];
        recipeAmts[ITEM_BRACELET] = [4, 2, 2];
    }

    function search() external {
        uint256 last = lastSearchAt[msg.sender];
        require(last == 0 || block.timestamp >= last + COOLDOWN, "cooldown");
        lastSearchAt[msg.sender] = block.timestamp;
            
        uint256[] memory ids = new uint256[](3);
        uint256[] memory amts = new uint256[](3);
        
        ids[0] = 1 + (_rand(1) % 6);
        ids[1] = 1 + (_rand(2) % 6);
        ids[2] = 1 + (_rand(3) % 6);

        amts[0] = 1;
        amts[1] = 1;
        amts[2] = 1;

        resources.mintBatch(msg.sender, ids, amts);
    }


    function craft(uint8 itemType) external {
        uint256[] memory ids = recipeIds[itemType];
        require(ids.length > 0, "recipe");
        uint256[] memory amts = recipeAmts[itemType];

        resources.burnBatchFrom(msg.sender, ids, amts);
        items.mintTo(msg.sender, itemType);
    }

    function _rand(uint256 salt) internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(block.prevrandao, block.timestamp, msg.sender, salt)));
    }
}
