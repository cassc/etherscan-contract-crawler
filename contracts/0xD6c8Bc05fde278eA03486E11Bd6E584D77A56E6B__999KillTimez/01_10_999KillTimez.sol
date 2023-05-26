//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;


// █████╗  █████╗  █████╗     ██╗  ██╗██╗██╗     ██╗  ████████╗██╗███╗   ███╗███████╗███████╗
//██╔══██╗██╔══██╗██╔══██╗    ██║ ██╔╝██║██║     ██║  ╚══██╔══╝██║████╗ ████║██╔════╝╚══███╔╝
//╚██████║╚██████║╚██████║    █████╔╝ ██║██║     ██║     ██║   ██║██╔████╔██║█████╗    ███╔╝
// ╚═══██║ ╚═══██║ ╚═══██║    ██╔═██╗ ██║██║     ██║     ██║   ██║██║╚██╔╝██║██╔══╝   ███╔╝
// █████╔╝ █████╔╝ █████╔╝    ██║  ██╗██║███████╗███████╗██║   ██║██║ ╚═╝ ██║███████╗███████╗
// ╚════╝  ╚════╝  ╚════╝     ╚═╝  ╚═╝╚═╝╚══════╝╚══════╝╚═╝   ╚═╝╚═╝     ╚═╝╚══════╝╚══════╝




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
Contract created by Ivan Rubio
Deployment By: LunarXY
*/
import "ERC721A.sol";
import "ERC721AQueryable.sol";
import "ECDSA.sol";
import "Ownable.sol";
import "ReentrancyGuard.sol";


contract _999KillTimez is ERC721AQueryable, Ownable, ReentrancyGuard {
    using Strings for uint256;
    using ECDSA for bytes32;

    //@dev adjust these values for your collection
    uint public maxSupply = 333;

    uint public wlMintCounter = 0;

    uint public vipMintCounter = 0;
    uint public maxVipMints = 130;

    uint public publicPrice = 0.0666 ether;
    uint public whitelistPrice = 0.0444 ether;


    //@dev byte-pack bools and address to save gas
    bool publicSaleStarted = false;
    bool whiteListStarted = true;
    bool vipStarted = true;

    mapping(address => uint) public giftReceived;

    /*@dev Reference Address to Compare ECDSA Signature
    Fill this in with your own WL Address
    To learn more about signatures check out
    https://docs.ethers.io/v5/api/signer/#:~:text=A%20Signer%20in%20ethers%20is,on%20the%20sub%2Dclass%20used.*/
    address private vipAddress = 0x150B0Bed2B8a0D293252b9910cc9ee47FeAb51Aa;
    address private whitelistAddress = 0xECDA7Af07E5F228fBF2e9f23186b251c3dA9deB6;

    /*
    43% Community Wallet
    13% Development Team
    28% Creador
    12% Community Manager
    4% Marketing*/
    address private communityPayoutAddress = 0x37fDf57B5bA51B777865753CD4b0F2949d8b4FfA;
    address private developmentPayoutAddress = 0x78Cca4e539EB68cc0b01A11034434BA67314456C;
    address private creatorPayoutAddress = 0x5F7F0560C7d8ECfD341620888df2BB072e064BF0;
    address private communityManagerPayoutAddress = 0x61C2138d7A63bf100eEAedE90a55a65736A3DFAD;
    address private marketingPayoutAddress = 0x58b54887DE1aE8D85351BE9112355465F9cD438D;


    /* @dev Used in TokenURI Function for exchanges.
        For more information about this standard check out
        https://docs.opensea.io/docs/metadata-standards
    */
    string public baseURI = "https://api.nft.lunarxy.com/v1/nft/metadata/999killtimez/";
    string public uriSuffix = ".json";


    // @dev these mappings track how many one has minted on public and WL respectively
    mapping(address => uint) public publicMints;
    mapping(address => uint) public wlMints;
    mapping(address => uint) public vipMints;
    //This is where the staking contract will be stored.

    constructor()
    ERC721A("999KillTimez", "999KT")
    {

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

    // @dev, helper hash function for WL Mint
    function hashMessageGift(uint number, uint gift, address sender)
    private
    pure
    returns (bytes32)
    {
        return keccak256(abi.encodePacked(number, gift, sender));
    }

    //END SIGNATURE VERIFICATION


    /* MINTING */

    //@dev The Max Someone Can Mint is Encoded In The Signature. Be careful
    function vipMint(uint amount, uint max, bytes memory signature) external {
        if (!vipStarted) revert SaleNotStarted();
        if (totalSupply() + amount > maxSupply) revert SoldOut();
        if (vipMintCounter + amount > maxVipMints) revert RoundSoldOut();
        if (vipMints[_msgSender()] + amount > max) revert MaxMints();
        if (!verifyAddressSigner(vipAddress, hashMessage(max, msg.sender), signature)) revert NotWL();

        vipMints[_msgSender()] += amount;
        vipMintCounter += amount;
        _mint(_msgSender(), amount);
    }


    //@dev The Max Someone Can Mint is Encoded In The Signature. Be careful
    function whiteListMint(uint amount, uint max, uint gift, bytes memory signature) external payable {

        if (!whiteListStarted) revert SaleNotStarted();
        if (totalSupply() + amount > maxSupply) revert SoldOut();
        if (!verifyAddressSigner(whitelistAddress, hashMessageGift(max, gift, msg.sender), signature)) revert NotWL();
        if (msg.value < (amount * whitelistPrice)) revert ValueTooLow();
        if (wlMints[_msgSender()] + amount > max) revert MaxMints();

        uint payout = amount * whitelistPrice;
        wlMints[msg.sender] += amount;

        // Other collections holders received 1 free NFT
        uint gift_diff = gift - giftReceived[_msgSender()];
        if (gift_diff > 0) {
            giftReceived[_msgSender()] = gift;
            amount += gift_diff;
        }

        wlMintCounter += amount;
        _mint(msg.sender, amount);


        spreadPayments(payout);

    }

    //@dev minting function for public sale
    function publicMint(uint amount) external payable {
        if (!publicSaleStarted) revert SaleNotStarted();
        if (totalSupply() + amount > maxSupply) revert SoldOut();
        if (msg.value < amount * publicPrice) revert ValueTooLow();

        publicMints[_msgSender()] += amount;
        _mint(msg.sender, amount);

        uint payout = amount * publicPrice;
        spreadPayments(payout);

    }

    function spreadPayments(uint payout) private {
        uint communityPayout = payout * 4300 / 10000;
        uint developmentPayout = payout * 1300 / 10000;
        uint creatorPayout = payout * 2800 / 10000;
        uint communityManagerPayout = payout * 1200 / 10000;
        uint marketingPayout = payout * 400 / 10000;

        (bool osCommunity,) = payable(communityPayoutAddress).call{value : communityPayout}("");
        (bool osDevelopment,) = payable(developmentPayoutAddress).call{value : developmentPayout}("");
        (bool osCreator,) = payable(creatorPayoutAddress).call{value : creatorPayout}("");
        (bool osCommunityManager,) = payable(communityManagerPayoutAddress).call{value : communityManagerPayout}("");
        (bool osMarketing,) = payable(marketingPayoutAddress).call{value : marketingPayout}("");
    }



    /* END MINTING */

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

    function setCommunityPayoutAddress(address _newAddress) external onlyOwner {
        require(_newAddress != address(0), "CAN'T PUT 0 ADDRESS");
        communityPayoutAddress = _newAddress;
    }

    function setdevelopmentPayoutAddress(address _newAddress) external onlyOwner {
        require(_newAddress != address(0), "CAN'T PUT 0 ADDRESS");
        developmentPayoutAddress = _newAddress;
    }

    function setCreatorPayoutAddress(address _newAddress) external onlyOwner {
        require(_newAddress != address(0), "CAN'T PUT 0 ADDRESS");
        creatorPayoutAddress = _newAddress;
    }

    function setCommunityManagerPayoutAddress(address _newAddress) external onlyOwner {
        require(_newAddress != address(0), "CAN'T PUT 0 ADDRESS");
        communityManagerPayoutAddress = _newAddress;
    }

    function setMarketingPayoutAddress(address _newAddress) external onlyOwner {
        require(_newAddress != address(0), "CAN'T PUT 0 ADDRESS");
        marketingPayoutAddress = _newAddress;
    }

    function setUriSuffix(string memory _newSuffix) external onlyOwner {
        uriSuffix = _newSuffix;
    }

    function setPublicStatus(bool status) external onlyOwner {
        publicSaleStarted = status;
    }

    function setWhiteListStatus(bool status) external onlyOwner {
        whiteListStarted = status;
    }

    function setVipStatus(bool status) external onlyOwner {
        vipStarted = status;
    }

    function setPublicPrice(uint64 _newPrice) external onlyOwner {
        publicPrice = _newPrice;
    }

    function setWhiteListPrice(uint64 _newPrice) external onlyOwner {
        whitelistPrice = _newPrice;
    }

    function setMaxVipSupply(uint16 _wlSupply) external onlyOwner {
        require(_wlSupply <= maxVipMints, "Cant Increase Size Of Collection");
        maxVipMints = _wlSupply;
    }

    function setMaxSupply(uint newSupply) external onlyOwner {
        require(newSupply <= maxSupply, "Cant Increase Size Of Collection");
        maxSupply = newSupply;
    }

    //END SETTERS


    function _startTokenId() internal view override returns (uint256) {
        return 1;
    }

    // FACTORY

    function tokenURI(uint256 tokenId)
    public
    view
    override(IERC721A, ERC721A)
    returns (string memory)
    {

        string memory currentBaseURI = baseURI;
        return
        bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), uriSuffix))
        : "";
    }


    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        (bool r1,) = payable(owner()).call{value : balance}("");
        require(r1);
    }

    function contractURI() public view returns (string memory) {
        return "https://alphainchain.io/contract-metadata.json";
    }
}