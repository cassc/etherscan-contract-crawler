// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
//access control
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
// Helper functions OpenZeppelin provides.
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

interface ImageDataInf{
    function getCDNImageForElement(string calldata element, uint16 level)external view returns(string memory);
    function getIPFSImageForElement(string calldata element, uint16 level)external view returns(string memory);
    function getAnnimationForElement(string calldata element)external view returns(string memory);
}

interface TokenURIInf{
    function maketokenURi(uint _tokenId, uint wlSpots, uint winChances, uint softClay ) external view returns(string memory);
    function contractURI() external view returns (string memory);
}

interface WinContr {
    function getReferalIncrease()external view returns(uint16);
    function updateAfterLoss(uint passportId, string calldata city, uint32 buildingId)external;
}

contract MetropolisWorldPassport is ERC721Enumerable, Ownable, AccessControl  {
    address private IMAGE_DATA_CONTRACT;
    ImageDataInf ImageContract;
    address private WIN_CONTRACT;
    WinContr WinContract;
    address private WL_CONTRACT;
    address private TURI_CONTRACT;
    TokenURIInf TuriContract;
    
    //defining the access roles
    bytes32 public constant UPDATER_ROLE = keccak256("UPDATER_ROLE");
    //bytes32 public constant BALANCE_ROLE = keccak256("BALANCE_ROLE");
    bytes32 public constant CONTRACT_ROLE = keccak256("CONTRACT_ROLE");
    //payment split contract
    address payable private _paymentSplit;
    
    // The tokenId is the NFTs unique identifier, it's just a number that goes
    // 0, 1, 2, 3, etc.
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds; //counter for token ids
    

    //updateable variables
    uint32 public _mintLimit = 5000;
    uint16 public _maxAllowedPerWallet = 301; //maximum allowed to mint per wallet
    string private _oddAvatar = "nomad";
    string private _evenAvatar = "citizen";
    
    uint256 public _navPrice = 0.12 ether;
    
    
    struct AccessToken {
        uint256 id;
        uint32 winChances;
        uint32 softClay; // max is 4 billion
        // string name;
        string rank;
        //string description;
        //string image;
        //string animation;
        //string cdnImage;
        string element;
        uint avatarWl;
        uint256[] whitelistSpots;
    }

    string[] elements = ["Fire", "Water", "Air", "Space", "Pixel", "Earth"];
    //store the list of minted tokens metadata to thier token id
    mapping(uint256 => AccessToken) nftAccessTokenAttribute;
    //give away wallets
    mapping(address=>uint16) _freeMintable; //winners of free passport are mapped here and can mint for free. 
    mapping(bytes => bool) _signatureUsed;

    //set up functions
    constructor(address imageContract, address admin) ERC721("Metropolis World Passport", "METWA") {
        //require(imageContract != address(0));
        IMAGE_DATA_CONTRACT = imageContract;
        ImageContract = ImageDataInf(IMAGE_DATA_CONTRACT);
        // I increment _tokenIds here so that my first NFT has an ID of 1.
        _tokenIds.increment();
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(UPDATER_ROLE, msg.sender);
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    //overides 
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Enumerable ,AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function contractURI() public view returns (string memory) {
        return TuriContract.contractURI();
    }


    /**
     * @dev Set up the addrese for other contracts which interact with this contract.
     * @param winContract The address of the win chances contract.
     * @param wlContract The address of the Whitelist Contract.
     * @param turiContract The address of the Token URI contract 
     * @notice Can only be called by wallets with UPDATER_ROLE 
     */
    function setWLContractAddress(address payable paymentContract, address winContract, address wlContract, address turiContract)external onlyRole(UPDATER_ROLE){
        // require(winContract != address(0));
        // require(wlContract != address(0));
        // require(turiContract != address(0));
        WIN_CONTRACT = winContract;
        WinContract = WinContr(WIN_CONTRACT);
        WL_CONTRACT = wlContract;
        TURI_CONTRACT = turiContract;
        TuriContract = TokenURIInf(TURI_CONTRACT);
        _paymentSplit = paymentContract;
    }

    function setImageContract(address imageContract)external onlyRole(UPDATER_ROLE){
        require(imageContract != address(0));
        IMAGE_DATA_CONTRACT = imageContract;
        ImageContract = ImageDataInf(IMAGE_DATA_CONTRACT);
    }

    //minting functions
    function _internalMint(address toWallet, uint32 winChance)internal {
        uint256 newItemId = _tokenIds.current();
        // make sure not above limit of available mints.
        require(newItemId <= _mintLimit, "To many minted");
        //make sure not already got 1
        require(balanceOf(toWallet) < _maxAllowedPerWallet, "address already owns max allowed");
        _safeMint(toWallet, newItemId);
        //randomly assign the element
        string memory elm = elements[newItemId % 6];
        //randomly assign the chracter WL spot.
        uint avwl = 1;//_oddAvatar;
        if (newItemId % 2 == 1) {
            //is an odd number
            avwl = 2;//_evenAvatar;
        }
        
        nftAccessTokenAttribute[newItemId] = AccessToken({
            id: newItemId,
            winChances: winChance,
            softClay: 0,
            rank: "N",
            element: elm,
            avatarWl: avwl,
            whitelistSpots: new uint256[](0)
        });
        // Increment the tokenId for the next person that uses it.
        _tokenIds.increment();
       
    }

    /**
     * @dev Used internally to mint free passports and send them to addreses eg. comp winners.
     * @param toWallet The address which the passport will be minted too.
     * @notice Can only be called by wallets with UPDATER_ROLE 
     */
    function freeMint(address toWallet)external onlyRole(UPDATER_ROLE) {
        _internalMint(toWallet, 1);   
    }

    /**
     * @dev Used by users who hvae been awarded a free passport. Checks against the list of approved wallets
     */
    function userFreeMint(uint16 mints)external{
        
        require(_freeMintable[msg.sender] >= mints, "not on the free mint list");
        for(uint16 i; i < mints; i++){
            //as comp winners they get an extra win chance too 
            _internalMint(msg.sender, 2);
            //remove free mint ability 
        }
        _freeMintable[msg.sender] -= mints;
    }

    function myFreeMints()external view returns(uint16){
        return _freeMintable[msg.sender];
    }


    function recoverSigner(bytes32 hash, bytes memory signature) internal pure returns (address) {
        bytes32 messageDigest = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32", 
                hash
            )
        );
        return ECDSA.recover(messageDigest, signature);
    }

    /**
     * @dev Bulk minitng function for users. 
     * @param numberOfMints the number of passports to be minted. 
     * @param toAddress the address the nft is going to. 
     * @param referrerTokenId the passport ID of the referrer, pass 0 if there is no referall. 
     */
    function bulkMint(uint16 numberOfMints, address toAddress, uint256 referrerTokenId, bytes32 hash, bytes memory signature)external payable {
        require(recoverSigner(hash, signature)==owner(),"invalid signature");
        require(!_signatureUsed[signature], "Signature has already been used.");
        require(numberOfMints < _maxAllowedPerWallet, "Trying to mint more then max allowed per wallet" );
        require(msg.value >= (numberOfMints * _navPrice), "not paid enough");
        require(balanceOf(msg.sender) < _maxAllowedPerWallet - numberOfMints, "address already owns max allowed");
        require(_tokenIds.current() + numberOfMints - 1 <= _mintLimit, "Will take you over max supply");
        _signatureUsed[signature] = true;
        for(uint16 i; i < numberOfMints; i++){
            if (referrerTokenId != 0){
                referralMint(referrerTokenId, toAddress);
            }else{
                _internalMint(toAddress, 1);
            }
        }
        //return the excess if any
        if (msg.value > (numberOfMints * _navPrice)){
            Address.sendValue(payable(msg.sender), (msg.value - (numberOfMints * _navPrice)));
        }
    }

    /**
     * @dev Standard minitng with the added functionaility of a referal mechamisum.
     * @param referrerTokenId The token id of the passport refering the mint 
     */
    function referralMint(uint256 referrerTokenId, address toAddress) internal {
        //tokenId is the Id of the Token referring the new mint.
        //this function increases win chances for each person refeered
        uint256 newItemId = _tokenIds.current();
        require(referrerTokenId < newItemId, "Invalid token ID");
        //require(referrerTokenId != 0, "Invalid token ID");
        _internalMint(toAddress, 2);
        nftAccessTokenAttribute[referrerTokenId]
            .winChances += WinContract.getReferalIncrease();
    }

    //Whitelist Functions
    // all the functions which created the proccess of adding or removing WL from the passport
    //city WL spots
    /**
     * @dev used by the WL contract to attache whitlis spots for cities to passport.
     * @param wlId The ID of the WL being attached
     * @param passportId the token ID of the passport which the WL is being attcahed to. 
     * @notice only callable by a wallet/contract with the CONTRACT_ROLE
     */
    function attachWLSpot(uint wlId, uint passportId)external onlyRole(CONTRACT_ROLE){
        //called from the WL contract adds WL to passport for city drop. 
        nftAccessTokenAttribute[passportId].whitelistSpots.push(wlId);
    }
    
    /**
     * @dev Get the WL spots a particular passport has.
     * @param passportId The token id of the passport 
     */
    function getWLSpots(uint passportId)external view returns(uint[] memory){
        return nftAccessTokenAttribute[passportId].whitelistSpots;
    }
    
    function detachCityWLSpot(uint passportId, uint index)external onlyRole(CONTRACT_ROLE){
        //called from the WL contract. 
        nftAccessTokenAttribute[passportId].whitelistSpots[index] = nftAccessTokenAttribute[passportId].whitelistSpots[nftAccessTokenAttribute[passportId].whitelistSpots.length-1];
        nftAccessTokenAttribute[passportId].whitelistSpots.pop();
    }
    
    //avatar whitelist spots
    function contractRemoveAvatarWL(uint256 tokenId, address owner)
        external
        onlyRole(CONTRACT_ROLE)
    {
        // when the user mints the avatar this is called by that contract and the WL is removed from the passport
        // can also be used to manually remove spot
        // we assume the avatar contract has checked the WL spot is correct.
        // check owner owns passport
        require(ownerOf(tokenId) == owner, "owner needs to own the passport");
        nftAccessTokenAttribute[tokenId].avatarWl = 0;
    }

    function manualAddAvatarWL(uint256 tokenId, uint avatar)
        external
        onlyRole(UPDATER_ROLE)
    {
        // for us to manually add a WL spot to the passport.
        nftAccessTokenAttribute[tokenId].avatarWl = avatar;
    }
    
    function checkAvatarWL(uint passportId)external view returns(uint){
        return nftAccessTokenAttribute[passportId].avatarWl;
    }

    function setAvatarWLNames(string calldata odd, string calldata even)
        external
        onlyRole(UPDATER_ROLE)
    {
        _oddAvatar = odd;
        _evenAvatar = even;
    }

    //Win Chance functions
    function userUpdateAfterLoss(uint passportId, string calldata city, uint32 buildingId)external{
        //called by user to update thier win chances after they loose
        require(ownerOf(passportId)==msg.sender, "You must own the passport to claim win chance increases");
        WinContract.updateAfterLoss(passportId, city, buildingId);
    }

    function increaseWinChance(uint passportId, uint16 inc)external onlyRole(CONTRACT_ROLE){
        nftAccessTokenAttribute[passportId].winChances += inc;
    }

    function decreaseWinChance(uint passportId, uint16 dec)external onlyRole(CONTRACT_ROLE){
        nftAccessTokenAttribute[passportId].winChances -= dec;
    }

    // view values
    function getWinChances(uint256 tokenId)external view returns (uint32) {
        //return the win chances of a specific token
        return nftAccessTokenAttribute[tokenId].winChances;
    }

    //Soft Clay functions
    // all the functions relating to the meteor dust process.
    function increaseSoftClay(uint passportId, uint32 amount)external onlyRole(CONTRACT_ROLE){
        nftAccessTokenAttribute[passportId].softClay += amount;
    }
    function decreaseSoftClay(uint passportId, uint32 amount)external onlyRole(CONTRACT_ROLE){
        nftAccessTokenAttribute[passportId].softClay -= amount;
    }
    function updateRank(uint256 tokenId, uint32 _pioneerLevel, uint32 _legendLevel)external onlyRole(CONTRACT_ROLE){
        // checks if the stamp count for a token id is high enough to move up a rank.
        // we run it each time a stamp is claimed
        if (nftAccessTokenAttribute[tokenId].softClay >= _legendLevel) {
            nftAccessTokenAttribute[tokenId].rank = "L";
        } else if (
            nftAccessTokenAttribute[tokenId].softClay >= _pioneerLevel &&
            nftAccessTokenAttribute[tokenId].softClay < _legendLevel
        ) {
            nftAccessTokenAttribute[tokenId].rank = "P";
        } else if (nftAccessTokenAttribute[tokenId].softClay < _pioneerLevel) {
            nftAccessTokenAttribute[tokenId].rank = "N";
        }
    }

    function getSoftClay(uint passportId)external view onlyRole(CONTRACT_ROLE) returns(uint32){
        return nftAccessTokenAttribute[passportId].softClay;
    }

    //Admin or Helper Functions
    // Mostly the ones use internaly to help user flow on the site.
    function setFreeMinters(address[] calldata winners)external onlyRole(UPDATER_ROLE){
        // used by us to add competition winners 
        // should not exceed 500 items but can be split of required 
        uint len = winners.length;
        for (uint16 i; i<len;i++){
            _freeMintable[winners[i]]+=1;
        }
    }

    function setPrice(uint256 price) external onlyRole(UPDATER_ROLE) {
        //set the price of minting.
        _navPrice = price;
    }

    function setMaxAllowed(uint16 maxA)external onlyRole(UPDATER_ROLE){
        //max allowed per wallet 
        _maxAllowedPerWallet = maxA;
    }

    function checkIfHasNFT(address owner)
        external
        view
        returns (AccessToken[] memory nft)
    {
        //a solution to get ownership detials
        uint256 bal = balanceOf(owner);
        AccessToken[] memory x = new AccessToken[](bal);
        for (uint256 i = 0; i < bal; i++) {
            uint tokenId = tokenOfOwnerByIndex(owner,i);
            x[i] = nftAccessTokenAttribute[tokenId];
        }
        return x;
    }


    function getCurrentTokenId() external view returns (string memory) {
        // we will use this in the snapshot before each drop
        // The idea being to loop through all the token id's from 1 up to this number and see who owns them,
        // reading each token URI to see the win chances.
        // we will do this on the front end.
        return Strings.toString(_tokenIds.current());
    }

    function setMintLimit(uint32 limt) public onlyRole(UPDATER_ROLE) {
        //change the mint limit to restrict the total number of NFT's that can be minted
        _mintLimit = limt;
    }
    
    function sectionOne(uint _tokenId)external view returns(bytes memory){
        // string memory rank = "Navigator";
        // if  (nftAccessTokenAttribute[_tokenId].softClay >= _legendLevel){
        //     rank = "Pioneer";
        // }
        string memory avatar = "Citizen";
        if (nftAccessTokenAttribute[_tokenId].avatarWl == 2){
            avatar = "Nomad";
        }
        bytes memory dataURI = abi.encodePacked(
            '{"name": "',
            "Passport: ", nftAccessTokenAttribute[_tokenId].element,
            '", "description": "',
            "",
            '", "image": "',
            ImageContract.getIPFSImageForElement(nftAccessTokenAttribute[_tokenId].element, 1),
            '", "animation_url": "',
            ImageContract.getAnnimationForElement(nftAccessTokenAttribute[_tokenId].element),
            '", "attributes": [{ "trait_type": "Avatar WL", "value": "',
            avatar,
            '"},{ "trait_type": "Rank", "value": "',
            nftAccessTokenAttribute[_tokenId].rank,
            '"},{ "trait_type": "Element", "value": "',
            nftAccessTokenAttribute[_tokenId].element
        );
        return dataURI;
    }
    // nftAccessTokenAttribute[_tokenId].description
    // //token URI's
    // ImageContract.getIPFSImageForElement(elm, 1),
    //         cdnImage: ImageContract.getCDNImageForElement(elm, 1)
    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        AccessToken memory accessTokenAttributes = nftAccessTokenAttribute[
            _tokenId
        ];
        return TuriContract.maketokenURi(_tokenId, accessTokenAttributes.whitelistSpots.length, accessTokenAttributes.winChances, accessTokenAttributes.softClay);
    }

    // Transfers the ETH out of the contract to the specified address.
    function withdraw() external {
        uint256 balance = address(this).balance;
        Address.sendValue(_paymentSplit, balance);
    }

    
}