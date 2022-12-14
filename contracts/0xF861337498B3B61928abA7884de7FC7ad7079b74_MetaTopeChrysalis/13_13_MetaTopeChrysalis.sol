//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @title Contract for MetaSkin's Chrysalis
 * Copyright 2022 MetaTope
 */
contract MetaTopeChrysalis is ERC1155, AccessControl, Ownable {
    uint256 public constant META_SKIN = 0;
    uint256 public maxTotalSupply;
    uint256 public totalSupply = 0;
    bool public uriEditable = true;
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    modifier onlyBurner() {
        require(hasRole(BURNER_ROLE, msg.sender), "Caller is not a burner");
        _;
    }

    /**
     * @dev the metadata url should be replaced
     * @param _maxTotalSupply maxTotalSupply
     */
    constructor(uint256 _maxTotalSupply) ERC1155("") {
        maxTotalSupply = _maxTotalSupply;
    }

    function mint(address _to, uint256 _amount) external onlyOwner {
        require(_amount + totalSupply <= maxTotalSupply, "Amount should be less than maxTotalSupply");
        _mint(_to, META_SKIN, _amount, "");
        totalSupply += _amount;
    }

    function burn(address _from, uint128 _amount) public virtual onlyBurner {
        _burn(_from, META_SKIN, _amount);
    }

    function setURI(string memory _pre, string memory _post) external onlyOwner {
        require(uriEditable, "URI no more editable");
        _setURI(string(abi.encodePacked(
            _pre,
            Strings.toString(META_SKIN),
            _post
        )));
    }

    function disableSetURI() external onlyOwner {
        uriEditable = false;
    }

    function setBurner(address burner) public virtual onlyOwner {
        _setupRole(BURNER_ROLE, burner);
    }

    function supportsInterface(bytes4 interfaceId) public view override (ERC1155, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}