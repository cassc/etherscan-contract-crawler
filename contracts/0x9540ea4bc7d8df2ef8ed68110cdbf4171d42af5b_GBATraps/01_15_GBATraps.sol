// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./GBAWhitelist.sol";

/// @author Andrew Parker
/// @title Ghost Busters: Traps NFT contract
contract GBATraps is ERC721, Ownable, ERC721Enumerable{
    constructor(
        string memory _uriBase,
        string memory _uriSuffix,
        address _whitelist
    ) ERC721("Ghostbusters: Afterlife Ghost Traps","GBAGT"){
        __uriBase   = _uriBase;
        __uriSuffix = _uriSuffix;
        whitelist = _whitelist;
    }

    event PauseTraps(bool _pause);

    address miniStayPuft;   // MiniStayPuft contract;
    address whitelist;      // Whitlelist contract
    string __uriBase;       // Metadata URI base
    string __uriSuffix;     // Metadata URI suffix

    bool public saleStarted;                    // Has sale started
    uint public whitelistEndTime;               // Time when tokens become publically available
    mapping(address => bool) public hasMinted;  // Has a given address minted
    uint constant TOKEN_MAX = 1000;             // Number of tokens that can exist
    uint constant TOKENS_GIVEAWAY = 50 ;        // Number of tokens that can be given away
    uint public tokensClaimed;                  // Number of tokens claimed
    uint tokensGiven;                           // Number of tokens given
    uint tokensMinted;                          // Total number of tokens minted

    enum State { Paused, Whitelist, Public, Final}

    /// Mint Giveaway
    /// @notice Mint tokens for giveaway
    /// @param numTokens Number of tokens to mint
    function mintGiveaway(uint numTokens) public onlyOwner {
        require(tokensGiven + numTokens <= TOKENS_GIVEAWAY,"tokensGiven");
        for(uint i = 0; i < numTokens; i++){
            tokensGiven++;
            _mint(msg.sender,++tokensMinted);
        }
    }

    /// Use trap
    /// @notice Function called by MSP when trapping mob
    /// @dev burns a token, can only be called by MSP
    /// @param trapper Address of trapper, burns one of their tokens
    function useTrap(address trapper) public{
        require(balanceOf(trapper) > 0,"No trap");
        require(msg.sender == miniStayPuft,"Traps: sender");
        _burn(tokenOfOwnerByIndex(trapper,0));
    }

    /// Mint a Trap (Whitelisted)
    /// @notice Mint a Token if you're on the whitelist. Must be after sale has started.
    /// @param merkleProof merkle proof for your address in the whitelist
    function mintWhitelisted(bytes32[] memory merkleProof) public{
        require(saleStarted,"saleStarted");
        require(tokensClaimed < TOKEN_MAX - TOKENS_GIVEAWAY,"tokensClaimed");
        require(!hasMinted[msg.sender],"minted");
        require(GBAWhitelist(whitelist).isWhitelisted(merkleProof,msg.sender),"whitelist");

        tokensClaimed++;
        hasMinted[msg.sender] = true;
        _mint(msg.sender,++tokensMinted);
    }

    /// Mint a Trap (Public)
    /// @notice Mint a Token if you're on the whitelist. Must be after whitelistEndTime.
    function mintPublic() public {
        require(saleStarted,"saleStarted");
        require(block.timestamp > whitelistEndTime,"whitelistEndTime");

        require(tokensClaimed < TOKEN_MAX - TOKENS_GIVEAWAY,"tokensClaimed");

        require(!hasMinted[msg.sender],"minted");

        tokensClaimed++;
        hasMinted[msg.sender] = true;
        _mint(msg.sender,++tokensMinted);
    }

    /// Countdown
    /// @notice Get seconds until end of whitelist, 0 if sale not started
    function countdown() public view returns(uint){
        if(!saleStarted || whitelistEndTime == 0){
            return 0;
        }else if(whitelistEndTime < block.timestamp){
            return 0;
        }else{
            return whitelistEndTime - block.timestamp;
        }
    }

    /// Start Sale
    /// @notice Start whitelisted giveaway
    function startSale() public onlyOwner{
        saleStarted = true;
        whitelistEndTime = block.timestamp + 1 days;
        emit PauseTraps(false);
    }

    /// Pause Sale
    /// @notice Pause whitelisted giveaway
    function pauseSale() public onlyOwner{
        saleStarted = false;
        emit PauseTraps(true);
    }

    /// Set Mini Stay Puft
    /// @notice Specify address of MSP contract
    function setMiniStayPuft(address _miniStayPuft) public onlyOwner{
        miniStayPuft = _miniStayPuft;
    }

    /// Mint State
    /// @notice Get current mint state
    /// @return State (enum value)
    function mintState() public view returns(State){
        if(tokensClaimed == TOKEN_MAX - TOKENS_GIVEAWAY){
            return State.Final;
        }else if(!saleStarted){
            return State.Paused;
        }else if(block.timestamp < whitelistEndTime){
            return State.Whitelist;
        }else{
            return State.Public;
        }
    }

    /// Token URI
    /// @notice ERC721 Metadata function
    /// @param _tokenId ID of token to check
    /// @return URI (string)
    function tokenURI(uint256 _tokenId) public view override  returns (string memory){
        require(_exists(_tokenId),"exists");

        if(_tokenId == 0){
            return string(abi.encodePacked(__uriBase,bytes("0"),__uriSuffix));
        }

        uint _i = _tokenId;
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }

        return string(abi.encodePacked(__uriBase,bstr,__uriSuffix));
    }

    /// Update URI
    /// @notice Update URI base and suffix
    /// @param _uriBase URI base
    /// @param _uriSuffix URI suffix
    /// @dev Pushing size limits, so rather than having an explicit lock function, it can be implicit by renouncing ownership.
    function updateURI(string memory _uriBase, string memory _uriSuffix) public onlyOwner{
        __uriBase   = _uriBase;
        __uriSuffix = _uriSuffix;
    }


    /// Supports Interface
    /// @notice Override ERC-165 function for conflict
    /// @param interfaceId Interface ID to check
    /// @return bool Contract supports this interface
    function supportsInterface(bytes4 interfaceId) public view override(ERC721,  ERC721Enumerable) returns (bool) {
        return ERC721Enumerable.supportsInterface(interfaceId);
    }

    /// Before Token Transfer
    /// @notice Override OpenZeppelin function conflict
    /// @param from from
    /// @param to to
    /// @param tokenId tokenId
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable){
        ERC721Enumerable._beforeTokenTransfer(from,to,tokenId);
    }
}