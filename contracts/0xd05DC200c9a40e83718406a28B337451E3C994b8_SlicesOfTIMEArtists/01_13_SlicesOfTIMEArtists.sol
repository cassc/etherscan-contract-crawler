// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";

contract SlicesOfTIMEArtists is ERC721 {
    modifier contractIsNotFrozen() {
        require(_frozen == false, "This function cannot be called anymore");

        _;
    }

    struct TokenData {
        uint256 totalTokens;
        uint256 nextToken;
    }

    TokenData private tokenData;

    bool public _paused = true;
    bool private _frozen;
    string private baseURI = "ipfs://unset-base-uri/";
    address public burnContract = 0x000000000000000000000000000000000000dEaD;

    constructor(address burnAddress) ERC721("SlicesOfTIMEArtists", "SOTA") {
        burnContract = burnAddress;
        tokenData.totalTokens = 17325;
    }

    // ONLY OWNER FUNCTIONS

    /**
     * @dev Sets the base URI for the tokens API.
     */
    function setBaseURI(string memory _uri) external onlyOwner contractIsNotFrozen {
        baseURI = _uri;
    }

    /**
     * @dev Sets the total amount of mint-able tokens
     */
    function setTotalTokens(uint256 _totalTokens) external onlyOwner contractIsNotFrozen {
        tokenData.totalTokens = _totalTokens;
    }

    /**
     * @dev Allows the owner to pause & unpause the contractMint functionality
     */
    function pauseContract(bool val) public onlyOwner contractIsNotFrozen {
        _paused = val;
    }

    /**
     * @dev Freezes the contract with no ability to unfreeze
     */
    function freezeContract() external onlyOwner {
        _frozen = true;
    }

    // END ONLY OWNER FUNCTIONS

    /**
     * @dev Mints a new token. Only callable by the burnContract address
     */
    function contractMint(address _address) external contractIsNotFrozen {
        require(!_paused, "Mint has not started or is paused right now");
        require(msg.sender == burnContract, "Only the burn contract can call this contract's mint function.");
        require(getRemainingTokens() >= 1, "No tokens left to be minted.");
        _mint(_address, tokenData.nextToken);
        tokenData.nextToken += 1;
    }

    /**
     * @dev returns total supply of tokens
     */
    function totalSupply() public view returns(uint256) {
        return uint256(tokenData.totalTokens);
    }

    /**
     * @dev Returns the remaining token count
     */
    function getRemainingTokens() public view returns (uint256) {
        return tokenData.totalTokens - tokenData.nextToken;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

}