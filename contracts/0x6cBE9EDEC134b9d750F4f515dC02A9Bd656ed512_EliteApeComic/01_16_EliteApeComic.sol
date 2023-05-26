// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./PVERC721.sol";

contract EliteApeComic is PVERC721 {
    uint256 public windowOpens;
    uint256 public windowCloses;

    IEliteApeCoinContract immutable eliteApeCoinContract;

    constructor(
        string memory _name, 
        string memory _symbol,  
        string memory _uri,
        uint256 _windowOpens,
        uint256 _windowCloses,
        address _eliteApeCoinContract
    ) PVERC721(_name, _symbol, _uri) {
        windowOpens = _windowOpens;
        windowCloses = _windowCloses;

        eliteApeCoinContract = IEliteApeCoinContract(_eliteApeCoinContract);         
    }                   

    function editWindows(
        uint256 _windowOpens, 
        uint256 _windowCloses
    ) external onlyOwner {
        require(_windowOpens < _windowCloses, "open window must be before close window");

        windowOpens = _windowOpens;
        windowCloses = _windowCloses;
    }      

    function mint(
        uint256 amount
    ) external {
        require (block.timestamp > windowOpens && block.timestamp < windowCloses, "Window closed");
        require(amount > 0, "amount not allowed");  

        eliteApeCoinContract.burnFromRedeem(msg.sender, 0, amount);

        _mintMany(msg.sender, amount);
    }       

    /**
     * @notice Returns the Uniform Resource Identifier (URI) for `tokenId` token. 
     */
    function tokenURI(uint256) public view override returns (string memory) {
        return uri;
    }             
}

interface IEliteApeCoinContract {
    function burnFromRedeem(address account, uint256 id, uint256 amount) external;
 }