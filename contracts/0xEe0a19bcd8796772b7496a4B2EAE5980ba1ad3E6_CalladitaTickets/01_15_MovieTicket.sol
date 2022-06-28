// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.6.0/contracts/access/Ownable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.6.0/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.6.0/contracts/utils/Strings.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.6.0/contracts/token/ERC721/IERC721.sol";
import "./library/Mintable.sol";

/**
 * @title CalladitaTickets contract
 * @author @FrankNFT.eth
 */
contract CalladitaTickets is ERC1155Supply, Mintable {
    using Strings for uint256;

    uint256 public constant POPCORN_TOKEN_MAX_SUPPLY = 100000;
    uint256 public constant MOVIE_TOKEN_MAX_SUPPLY = 20000;
    uint256 public constant MOVIE_TOKEN_ID = 0;
    uint256 public constant PORNCORN_TOKEN_ID = 1;
    uint256 public tokenPrice = 0.02 ether; 
    uint256 public teamWithdraw;
    uint256 public cyberWithdraw;  
    uint256 public totalWithdraw;

    uint public constant MAX_PURCHASE = 26; // set 1 to high to avoid some gas

    address private constant TEAM = 0xd105eA47f73A120Fd2EfE1151E73231A0f9445FD;
    address private constant CYBER = 0xA422bfFF5dABa6eeeFAFf84Debf609Edf0868C5f;
    address private constant MOVIE = 0x1Bb96B19858b12d91B8512580147A03cCa62C29e;

    bool public saleIsActive;

    IERC721 calladita;

    mapping(uint256 => bool) private tokenUsed;

    event priceChange(address _by, uint256 price);

    constructor() ERC1155("ipfs://QmSyt9T8Gsxt4so2zcB5sCMjzQhfhs9vmo3whLhNawKfWX/") {
        // ERC721's we interact with (mainnet)
        calladita = IERC721(0xdCb68d47423d244319a5101eAe78716AffBa8655);
    }

    /**
     * Pause sale if active, make active if paused
     */
    function flipSaleState() external onlyMinter {
        saleIsActive = !saleIsActive;
    }

    /**
    *  @dev set contract 
    */
    function setContract(address token) external onlyMinter {
        calladita = IERC721(token);
    }

    /**
    * @dev Set new baseURI
    */
    function setURI(string memory newuri) external onlyMinter {
        _setURI(newuri);
    }

        /**     
    * Set price 
    */
    function setPrice(uint256 price) external onlyMinter {
        tokenPrice = price;
        emit priceChange(msg.sender, tokenPrice);
    }

    /**
     * @dev Removing the token substituion and replacing it with the implementation of the ERC721
     */
    function uri(uint256 token) public view virtual override returns (string memory) {
        string memory baseURI = super.uri(token);
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, token.toString())) : "";
    }

    /**
     * @dev airdrop a specific token to a list of addresses
     */
    function airdrop(address[] calldata addresses, uint256 token, uint numberOfTokens) external onlyMinter {
        if (token==0){
            require(totalSupply(MOVIE_TOKEN_ID) + numberOfTokens <= MOVIE_TOKEN_MAX_SUPPLY, "Reserve would exceed max supply of Tokens");
        }else{
            require(totalSupply(POPCORN_TOKEN_MAX_SUPPLY) + numberOfTokens <= POPCORN_TOKEN_MAX_SUPPLY, "Reserve would exceed max supply of Tokens");
        }
        uint length = addresses.length;
        for (uint i=0; i < length;) {
            _mint(addresses[i], token, numberOfTokens, "");
            unchecked{ i++;}
        }
    }

    modifier mintConditions (uint numberOfTokens) {
        require(saleIsActive,"Sale NOT active yet");
        require(numberOfTokens != 0, "numberOfNfts cannot be 0");
        require(numberOfTokens < MAX_PURCHASE, "Can only mint 25 tokens at a time");
        require(totalSupply(MOVIE_TOKEN_ID) + numberOfTokens <= MOVIE_TOKEN_MAX_SUPPLY, "Purchase would exceed max supply of Tokens");
        _;
    }

    function mintWithCaladita(uint[] calldata tokenIds) external mintConditions(tokenIds.length){
        uint amount;
        uint length = tokenIds.length;
        for (uint i=0; i < length;) {
            if (!tokenUsed[tokenIds[i]] && calladita.ownerOf(tokenIds[i])==msg.sender){ 
                tokenUsed[tokenIds[i]]=true;
                unchecked{ amount++;}
            }
            unchecked{ i++;}
        }
        _mint(msg.sender, MOVIE_TOKEN_ID, amount, "");
        _mint(msg.sender, PORNCORN_TOKEN_ID, 10*tokenIds.length, "");
    }

    function mintWithPopcorn(uint numberOfTokens) external payable mintConditions(numberOfTokens){
        require(balanceOf(msg.sender,PORNCORN_TOKEN_ID)>=numberOfTokens,"not enough popcorn");
        require(tokenPrice * numberOfTokens <= msg.value, "Ether value sent is not correct");  
        _mint(msg.sender, MOVIE_TOKEN_ID, numberOfTokens, "");
        _burn(msg.sender, PORNCORN_TOKEN_ID, numberOfTokens);
        _mintEligiblePOPCORN(msg.sender,numberOfTokens);
        totalWithdraw += msg.value;
        if(totalWithdraw>240 ether){
            teamWithdraw += msg.value*15/100;
            cyberWithdraw += msg.value*15/100;
        }else{
            teamWithdraw+= msg.value*5/100;
        }
    }

    function calladitaUsed(uint id) external view returns (bool){
        return tokenUsed[id];
    }

    function _mintEligiblePOPCORN(address mintTo, uint multiplier) internal {
        if (totalSupply(PORNCORN_TOKEN_ID) > POPCORN_TOKEN_MAX_SUPPLY-1){
            return;
        }
        if (totalSupply(MOVIE_TOKEN_ID) < 3000) {
            _mint(mintTo, PORNCORN_TOKEN_ID, 5*multiplier, "");
        }
        else if (totalSupply(MOVIE_TOKEN_ID)  < 5000) {
            _mint(mintTo, PORNCORN_TOKEN_ID, 3*multiplier, "");
        }
        else if (totalSupply(MOVIE_TOKEN_ID)  < 10000) {
            _mint(mintTo, PORNCORN_TOKEN_ID, 2*multiplier, "");
        }
        else if (totalSupply(MOVIE_TOKEN_ID)  < 15000){
            _mint(mintTo, PORNCORN_TOKEN_ID, 1, "");
        }
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "Insufficent balance");
        _withdraw(TEAM, teamWithdraw);
        _withdraw(CYBER, cyberWithdraw);
        _withdraw(MOVIE, address(this).balance);
        teamWithdraw=0;
        cyberWithdraw=0;
    }

        /** 
     * @dev calladitaInWallet
     * @return tokens id owned by the given address
     * This read function is O(totalSupply). If calling from a separate contract, be sure to test gas first.
     * It may also degrade with extremely large collection sizes (e.g >> 10000), test for your use case.
     */
    function calladitaInWallet(address _owner) external view returns (uint256[] memory){
        uint256 ownerTokenCount = calladita.balanceOf(_owner);
        uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
        uint256 currentTokenId = 0;
        uint256 ownedTokenIndex = 0;

        while ( ownedTokenIndex < ownerTokenCount && currentTokenId < 2412 ) { /// MAGIC number is the calladita max token count
            if (_caladitaSafeOwnerOf(currentTokenId) == _owner) {
                ownedTokenIds[ownedTokenIndex] = currentTokenId;
                unchecked{ ownedTokenIndex++;}
            }
            unchecked{ currentTokenId++;}
        }
        return ownedTokenIds;
    }

    function _caladitaSafeOwnerOf(uint256 tokenId) private view returns (address owner){
        try calladita.ownerOf(tokenId) returns (address v) {
            return v;
        } catch (bytes memory /*lowLevelData*/) {
            return address(0);
        }
    }

    ///////////// Add name and symbol for etherscan /////////////////
    function name() public pure returns (string memory) {
        return "Calladita Movie Tickets";
    }

    function symbol() public pure returns (string memory) {
        return "POP";
    }

    /**
    * Helper method to allow ETH withdraws.
    */
    function _withdraw(address _address, uint256 _amount) internal {
        (bool success, ) = _address.call{ value: _amount }("");
        require(success, "Failed to widthdraw Ether");
    }

    // contract can recieve Ether
    receive() external payable { 
        totalWithdraw += msg.value;
        if(totalWithdraw>240 ether){
            teamWithdraw += msg.value*15/100;
            cyberWithdraw += msg.value*15/100;
        }else{
            teamWithdraw+= msg.value*5/100;
        }
    }
}