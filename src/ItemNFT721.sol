// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

contract ItemNFT721 is ERC721, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    uint256 private nextId;
    string private baseURI_;
    mapping(uint256 => uint8) public itemTypeOf;

    constructor(string memory baseUri_) ERC721("Items", "ITEM") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        baseURI_ = baseUri_;
        nextId = 1;
    }

    function mintTo(address to, uint8 itemType) external onlyRole(MINTER_ROLE) returns (uint256) {
        uint256 id = nextId++;
        _safeMint(to, id);
        itemTypeOf[id] = itemType;
        return id;
    }

    function burn(uint256 tokenId) external onlyRole(BURNER_ROLE) {
        _burn(tokenId);
        delete itemTypeOf[tokenId];
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI_;
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
