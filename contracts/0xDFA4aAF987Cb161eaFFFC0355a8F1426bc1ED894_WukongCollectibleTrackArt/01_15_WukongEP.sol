// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol';
import '@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol';

/*
* @title ERC1155 token for Wukong
*/
contract WukongCollectibleTrackArt is ERC1155, ERC1155Supply, ERC1155Burnable, Ownable {

    // Update MAX NUMBER OF TRACKS for this specific EP
    uint256 private MAX_NFTS = 30;
    uint256 private PHOENIX_RAVE = 1;
    uint256 private LEGEND_OF_WFH = 2;
    uint256 private CURRENT_TOKEN_ID = 1;

    string public baseTokenURI;

    uint256 public purchaseWindowOpens = 1662483656;

    string public name = "Wukong Collectible Track Art";
    string public symbol = "WCTA";

    uint256[] public priceArr = new uint256[](MAX_NFTS); 
    uint256[] public supplyArr = new uint256[](MAX_NFTS); 
    address[] public airDropHolders;

    event RedeemedForCard(uint256 indexed indexToRedeem, uint256 indexed indexToMint, address indexed account, uint256 amount);
    event Purchased(uint256 indexed index, address indexed account, uint256 amount);
    event SupplyCount(uint256 indexed countPR ,uint256 indexed countLWH);
    event TokenPrice(uint256 indexed price);
    event SingleSupplyCount(uint256 indexed count);

    constructor(
        string memory baseURI
    ) ERC1155(baseURI){
        _mint(0xdB3c309bdf0BB861336f334bc5C0ea6e1d3cf5dD, 1, 512, "");
        priceArr[PHOENIX_RAVE-1] = 0.0088 ether;
        supplyArr[PHOENIX_RAVE-1] = 488;
        MAX_NFTS--;
        _mint(0xdB3c309bdf0BB861336f334bc5C0ea6e1d3cf5dD, 2, 512, "");
        priceArr[LEGEND_OF_WFH-1] = 0.0088 ether;
        supplyArr[LEGEND_OF_WFH-1] = 488;
        MAX_NFTS--;
        CURRENT_TOKEN_ID = 3;
        setBaseURI(baseURI);
    }

    /**
    * @notice to create a new token
    *
    * @param _price price for new track
    * @param individualSupply set how much equity wukong is holding
    * @param saleSupply set how much equity will be giving to supporters of track drop
    */
    function createNewTrack(uint256 _price, uint256 individualSupply, uint256 saleSupply) external onlyOwner {
        require(MAX_NFTS> 0, "No more supply left for soundtracks");
        _mint(0xdB3c309bdf0BB861336f334bc5C0ea6e1d3cf5dD, CURRENT_TOKEN_ID, individualSupply, "");
        priceArr[CURRENT_TOKEN_ID-1] = _price;
        supplyArr[CURRENT_TOKEN_ID-1] = saleSupply;
        CURRENT_TOKEN_ID++;
        MAX_NFTS--;
    }

    /**
    * @notice deduct the supply count after the minting of token
    *
    * @param tokenID token id of the token to deduct the supply from
    */
    function deductCount(uint256 tokenID) private{
        uint256 supplyCount = supplyArr[tokenID-1];
        supplyArr[tokenID-1] = supplyCount - 1;
    }

    /**
    * @notice deduct the supply count after the minting of token
    *
    * @param tokenID token id of the token to deduct the supply from
    * @param count number of supply to deduct by
    */
    function massDeductCount(uint256 tokenID, uint256 count) private{
        uint256 supplyCount = supplyArr[tokenID-1];
        supplyArr[tokenID-1] = supplyCount - count;
    }

    /**
    * @notice airdrop function
    *
    */
    function airdrop() public onlyOwner {
        for (uint256 i = 0; i < airDropHolders.length; i++){
        _mint(airDropHolders[i], 1, 1, "");
        deductCount(1);
        _mint(airDropHolders[i], 2, 1, "");
        deductCount(2);
        }
    }

    /**
    * @notice individual airdrop function
    *
    * @param userAddress Address to airdrop to
    * @param tokenID Token to airdrop to user
    */
    function airDropSingleUserWithTokenId(address userAddress, uint256 tokenID) external onlyOwner {
        _mint(userAddress,tokenID, 1, "");
        deductCount(tokenID);
    }

    /**
    * @notice to mass mint for testing. To delete after testing
    *
    * @param count number to mint at one go
    */
    function massMint(uint256 count) external onlyOwner {
        _mint(0xdB3c309bdf0BB861336f334bc5C0ea6e1d3cf5dD,PHOENIX_RAVE, count, "");
        massDeductCount(PHOENIX_RAVE, count);
        _mint(0xdB3c309bdf0BB861336f334bc5C0ea6e1d3cf5dD,LEGEND_OF_WFH, count, "");
        massDeductCount(LEGEND_OF_WFH, count);
    }

    /**
    * @notice to mass mint for testing. To delete after testing
    *
    * @param userAddress Address to mass mint to
    * @param count number to mint at one go
    * @param tokenId tokenID to mass mint to self
    */
    function massMintToken(address userAddress, uint256 count, uint256 tokenId) external onlyOwner {
        _mint(userAddress,tokenId, count, "");
        massDeductCount(tokenId, count);
    }

    /**
    * @notice to increase supply of track mints
    *
    * @param tokenId tokenID of supply you want to increase
    * @param amount amount to increase by
    */
    function updateSupply(uint256 tokenId, uint256 amount) external onlyOwner {
        supplyArr[tokenId-1] += amount;
    }

    /**
    * @notice for testing to get number of supply left
    *
    */
    function checkSupply() external {
        uint256 countPR = supplyArr[PHOENIX_RAVE-1];
        uint256 countLWH = supplyArr[LEGEND_OF_WFH-1];
        emit SupplyCount(countPR, countLWH);
    }


    /**
    * @notice to check the price of specified token
    *
    * @param tokenId input to check price of specified token
    */
    function checkPrice(uint256 tokenId) external {
        uint256 price = priceArr[tokenId-1];
        emit TokenPrice(price);
    }

    /**
    * @notice for testing to get number of supply left for specific token ID
    *
    * @param tokenID tokenID of supply you want to check
    */
    function checkSupplyWithTokenID(uint256 tokenID) external onlyOwner {
        uint256 count = supplyArr[tokenID-1];
        emit SingleSupplyCount(count);
    }

    /**
    * @notice individual airdrop function
    *
    * @param userAddress Address to airdrop to
    */
    function airDropSingleUser(address userAddress) external onlyOwner {
        _mint(userAddress,1, 1, "");
        deductCount(1);
        _mint(userAddress,2, 1, "");
        deductCount(2);
    }

    /**
    * @notice purchase cards during public sale
    *
    * @param trackNum track number to purchase
    */
    function purchase(uint256 trackNum) public payable {
        require(block.timestamp >= purchaseWindowOpens);
        _purchase(trackNum);

    }

    /**
    * @notice global purchase function used in early access and public sale
    *
    * @param trackNum Track Number user wants to purchase
    */
    function _purchase(uint256 trackNum) private {
        require(supplyArr[trackNum-1] > 0 , "No more supply left for track");
        require(msg.value == priceArr[trackNum-1], "Invalid pricing please try again");

        _mint(msg.sender, trackNum, 1, "");
        uint256 supplyCount = supplyArr[trackNum-1];
        supplyArr[trackNum-1] = supplyCount -  1;
        emit Purchased(trackNum, msg.sender, 1);
    }

    /**
    * @notice Initial function to set list of users for airdrop
    *
    * @param addresses list of addresses containing people to airdrop first 88 tracks to
    */
    function setFirstDropGroup(address[] calldata addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            airDropHolders.push(addresses[i]);
        }
    }
    
    function burn(
        address account,
        uint256 id,
        uint256 value
    ) public virtual override onlyOwner{

        _burn(account, id, value);
    }

    function burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory values
    ) public virtual override onlyOwner{

        _burnBatch(account, ids, values);
    }

    /**
    * @notice Sets the specific pricing for specific token
    *
    * @param tokenId the token id to set the price
    * @param _price new price you want the token to be at
    */
    function _setTokenPrice(uint256 tokenId, uint256 _price) external onlyOwner{
        priceArr[tokenId-1] = _price;
    }

    /**
    * @notice Increase the supply for specific token
    *
    * @param tokenId the token id to set the price
    * @param count count to increase the token supply to
    */
    function _updateTokenSupply(uint256 tokenId, uint256 count) external onlyOwner{
        uint256 currSupply = supplyArr[tokenId-1];
        supplyArr[tokenId-1] = currSupply + count;
    }

    // setters
    function setBaseURI(string memory _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    /**
    * @notice returns the metadata uri for a given id
    *
    * @param _id the card id to return metadata for
    */
    function uri(uint256 _id) public view override returns (string memory) {
            require(exists(_id), "URI: nonexistent token");

            return string(abi.encodePacked(super.uri(_id), Strings.toString(_id)));
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override(ERC1155, ERC1155Supply) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }  
}