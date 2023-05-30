//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

error SaleNotStarted();
error RoundSoldOut();
error PublicSaleStillLive();
error MaxMints();
error SoldOut();
error ValueTooLow();
error NotWL();
error NotVIP();
error NotAllowedToCreateReferralCodes();



/*
0xSimon_
Deployment By: ______
*/
import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/Ownable.sol";



contract WealthyTedz is ERC721AQueryable, Ownable {
    using Strings for uint256;
    using ECDSA for bytes32;


    //@dev adjust these values for your collection
    uint public maxSupply = 10200;
    uint public wlMintCounter = 0;
    uint public maxWL = 1200;
    uint public vipMintCounter = 0;
    uint public maxVipMints = 1000;
    uint public publicPrice = 0.65 ether;
    uint public presalePrice = 0.45 ether;
    uint public referralPrice = 0.65 ether;
    uint public referralPercent = 10; //10%


    uint public maxPublicMints = 10;


    //@dev byte-pack bools and address to save gas
    bool publicSaleStarted;
    bool presaleStarted;
    bool presaleReferralStarted;
    bool referralStarted;
    bool vipStarted;


    bool public revealed;


    /*@dev Reference Address to Compare ECDSA Signature
    Fill this in with your own WL Address
    To learn more about signatures check out
    https://docs.ethers.io/v5/api/signer/#:~:text=A%20Signer%20in%20ethers%20is,on%20the%20sub%2Dclass%20used.*/
    address private whitelistAddress;
    address private vipAddress;
    address private referralAuthorizer;


    /* @dev Used in TokenURI Function for exchanges.
        For more information about this standard check out
        https://docs.opensea.io/docs/metadata-standards
    */
    string public baseURI;
    string public notRevealedUri;
    string public uriSuffix = ".json";


    // @dev these mappings track how many one has minted on public and WL respectively
    mapping(address => uint) public publicMints;
    mapping(address => uint) public presaleMints;
    mapping(address => uint) public vipMints;
    //This is where the staking contract will be stored.
    mapping(address => bool) approvedReceiver;
    bool tradingEnabled;

    constructor()
        ERC721A("Wealthy Tedz", "WTD")

    {
        setNotRevealedURI("ipfs://QmaMwCtT8wcCKAqUSurR2nyhRaGYXG28pJQ3dzNCqmr5ye");
    }



       //SIGNATURE VERIFICATION

    /*@dev helper function for WL sale
        returns true if reference address and signature match
        false otherwise
        Read more about ECDSA @openzeppelin https://docs.openzeppelin.com/contracts/2.x/utilities
    */
    function verifyAddressSigner(
        address referenceAddress,
        bytes32 messageHash,
        bytes memory signature
    ) internal pure returns (bool) {
        return
            referenceAddress ==
            messageHash.toEthSignedMessageHash().recover(signature);
    }


    // @dev, helper hash function for WL Mint
    function hashMessage(uint number, address sender)
        private
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(number, sender));
    }

    //END SIGNATURE VERIFICATION


    /* MINTING */
    function teamMint(address to ,uint amount) external onlyOwner{
        require(totalSupply() + amount <=maxSupply,"Sold Out");
        _mint(to,amount);
    }

    //@dev minting function for public sale
    function publicMint(uint amount) external payable{
        if(!publicSaleStarted) revert SaleNotStarted();
        if(totalSupply() + amount > maxSupply) revert SoldOut();
        if(publicMints[_msgSender()] + amount > maxPublicMints) revert MaxMints();
        if(msg.value < amount * publicPrice) revert ValueTooLow();

        publicMints[_msgSender()]+=amount;
        _mint(msg.sender,amount);

    }

    //@dev this functions as redemption mint
    function vipMint(uint amount, uint max, bytes memory signature) external {
        if(!vipStarted) revert SaleNotStarted();
        if(totalSupply() + amount > maxSupply) revert SoldOut();
        if(vipMintCounter + amount > maxVipMints) revert RoundSoldOut();
        if(vipMints[_msgSender()] + amount > max) revert MaxMints();
        if(!verifyAddressSigner(vipAddress,hashMessage(max, msg.sender),signature)) revert NotWL();

        vipMints[_msgSender()] += amount;
        vipMintCounter += amount;
        _mint(_msgSender(),amount);

    }


    //@dev The Max Someone Can Mint is Encoded In The Signature. Be careful
    function presaleMint(uint amount, uint max, bytes memory signature)  external payable {

       if(!presaleStarted) revert SaleNotStarted();
       if(totalSupply() + amount > maxSupply) revert SoldOut();
       if(wlMintCounter + amount > maxWL) revert RoundSoldOut();
       if(!verifyAddressSigner(whitelistAddress, hashMessage(max,msg.sender), signature)) revert NotWL();
       if(msg.value < amount * presalePrice) revert ValueTooLow();
       if(presaleMints[_msgSender()] + amount > max) revert MaxMints();


        presaleMints[msg.sender]+=amount;
        wlMintCounter += amount;
        _mint(msg.sender,amount);


    }


    //@dev The Max Someone Can Mint is Encoded In The Signature. Be careful
    function presaleReferralMint(uint amount, uint max, bytes memory signature, bytes memory authCode, bytes memory referralCode) external payable {

        if (!presaleReferralStarted) revert SaleNotStarted();

        if (totalSupply() + amount > maxSupply) revert SoldOut();
        if (wlMintCounter + amount > maxWL) revert RoundSoldOut();
        if (!verifyAddressSigner(whitelistAddress, hashMessage(max, msg.sender), signature)) revert NotWL();
        if (msg.value < amount * presalePrice) revert ValueTooLow();
        if (presaleMints[_msgSender()] + amount > max) revert MaxMints();

        bytes32 refHash = keccak256(abi.encodePacked("REFER"));
        address referrer = refHash.toEthSignedMessageHash().recover(referralCode);

        bytes32 authHash = keccak256(abi.encodePacked("AUTH", referrer));
        if (authHash.toEthSignedMessageHash().recover(authCode) != referralAuthorizer) revert NotAllowedToCreateReferralCodes();

        uint payout = msg.value * referralPercent / 100;
        (bool os,) = payable(referrer).call{value : payout}("");


        presaleMints[msg.sender] += amount;
        wlMintCounter += amount;
        _mint(msg.sender, amount);


    }

    /*
    Referral Function
    @param amount - amount that user wants to mint
    @param authCode - an authorization code that checks if the signer of referralCode is allowed to issue referral codes
    @param referralCode - a user's referral code. It's a signature encoded with ['string']['REFER']

    @notice we verify that
    1. ETH Sent is High Enough
    2. Referral Sale Has Started
    3. Collection is not sold out
    4. The signer of referralCode is authorized by referralAuthorizer to issue referral codes
    */

    function referralMint(uint amount, bytes memory authCode, bytes memory referralCode) external payable {
        if(msg.value < amount * referralPrice) revert ValueTooLow();
        if(!referralStarted) revert SaleNotStarted();
        if(totalSupply() + amount > maxSupply) revert SoldOut();
        bytes32 refHash =   keccak256(abi.encodePacked("REFER"));
        address referrer = refHash.toEthSignedMessageHash().recover(referralCode);
        bytes32 authHash = keccak256(abi.encodePacked("AUTH",referrer));
        if(authHash.toEthSignedMessageHash().recover(authCode) != referralAuthorizer) revert NotAllowedToCreateReferralCodes();

        uint payout = msg.value * referralPercent / 100;
        (bool os,) = payable(referrer).call{value:payout}("");
        require(os);

         _mint(msg.sender,amount);

    }

    /* END MINTING */



    function flipReveal() public onlyOwner {
        revealed = !revealed;
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setWlAddress(address _newAddress) external onlyOwner {
        require(_newAddress != address(0), "CAN'T PUT 0 ADDRESS");
        whitelistAddress = _newAddress;
    }
    function setVipAddress(address _newAddress) external onlyOwner {
        require(_newAddress != address(0), "CAN'T PUT 0 ADDRESS");
        vipAddress = _newAddress;
    }
    function setReferralAuthorizer(address _newAddress) external onlyOwner {
        require(_newAddress != address(0), "CAN'T PUT 0 ADDRESS");
        referralAuthorizer = _newAddress;
    }
    function setUriSuffix(string memory _newSuffix) external onlyOwner{
        uriSuffix = _newSuffix;
    }

      function setPublicStatus(bool status) external onlyOwner{
        publicSaleStarted = status;
    }
    function setPresaleStatus(bool status) external onlyOwner{
        presaleStarted = status;
    }
    function setPresaleReferralStatus(bool status) external onlyOwner {
        presaleReferralStarted = status;
    }

    function setVipStatus(bool status) external onlyOwner{
        vipStarted = status;
    }
    function setReferralStatus(bool status) external onlyOwner{
        referralStarted = status;
    }

    function setPublicPrice(uint64 _newPrice) external onlyOwner {
        publicPrice = _newPrice;
    }
    function setPresalePrice(uint64 _newPrice) external onlyOwner{
        presalePrice = _newPrice;
    }

    function setWlSupply(uint16 _wlSupply) external onlyOwner{
        require(_wlSupply <= maxSupply,"Cant Increase Size Of Collection");
        maxWL = _wlSupply;
    }
    function setMaxVipSupply(uint16 _wlSupply) external onlyOwner{
        require(_wlSupply <= maxSupply,"Cant Increase Size Of Collection");
        maxVipMints = _wlSupply;
    }
    function setMaxSupply(uint newSupply) external onlyOwner{
        require(newSupply <= maxSupply,"Cant Increase Size Of Collection");
        maxSupply = newSupply;
    }
    function setMaxPublicMints(uint amount) external onlyOwner{
        maxPublicMints = amount;
    }

    function setReferralPrice(uint newPrice) external onlyOwner{
        referralPrice = newPrice;
    }
    function setReferralPercent(uint newPercent) external onlyOwner{
        require(newPercent <= 100,"Should Never Pay More than 100% Of Value");
        referralPercent = newPercent;
    }
    function setTradingEnabled(bool status) external onlyOwner{
        tradingEnabled = status;
    }


    //END SETTERS




    // FACTORY

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721A)
        returns (string memory)
    {
        if (revealed == false) {
            return notRevealedUri;
        }

        string memory currentBaseURI = baseURI;
        return
            bytes(currentBaseURI).length > 0
                ? string(abi.encodePacked(currentBaseURI, tokenId.toString(),uriSuffix))
                : "";
    }

    //Override the transferFrom function
    function transferFrom(address from, address to, uint tokenId) public override (ERC721A){
        require(approvedReceiver[msg.sender] || tradingEnabled, "Trading is not live");
        super.transferFrom(from, to, tokenId);
    }
    function setReceiverStatus(address receiver, bool status) public onlyOwner {
        require(receiver != address(0), "CAN'T PUT 0 ADDRESS");
        approvedReceiver[receiver] = status;
    }


    function withdraw() public  onlyOwner {
        uint256 balance = address(this).balance;
        (bool r1, ) = payable(owner()).call{value: balance }("");
        require(r1);
  }

}