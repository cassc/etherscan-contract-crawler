// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./ERC20Contract.sol";

contract ERC20Factory is Ownable {

    mapping(uint256 => address) public deployments;
    ERC20Contract[] private tokens;
    address public treasuryAddress;
    uint16 public treasuryBasisPoints;
    uint256 public nextId = 1;

    constructor(address _treasuryAddress, uint16 _treasuryBasisPoints) {
        treasuryAddress = _treasuryAddress;
        treasuryBasisPoints = _treasuryBasisPoints;
    }

    function updateConfig(address _treasuryAddress, uint16 _treasuryBasisPoints) external onlyOwner {
        treasuryBasisPoints = _treasuryBasisPoints;
        treasuryAddress = _treasuryAddress;
    }

    function getDeployedTokens() external view returns (ERC20Contract[] memory) {
        return tokens;
    }

    function deploy(
        string memory _name,
        string memory _symbol,
        uint256 _totalSupply,
        uint256 _decimals
    ) external {
        require(_totalSupply > 0,  "Bad supply");
        ERC20Contract token = new ERC20Contract(
            _name,
            _symbol,
            _totalSupply,
            _decimals,
            treasuryBasisPoints,
            treasuryAddress,
            msg.sender
        );
        deployments[nextId++] = address(token);
        tokens.push(token);
    }
}