//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


//         _    _       _           ___ _   _  ____ _   _    _    ___ _   _
//        / \  | |_ __ | |__   __ _|_ _| \ | |/ ___| | | |  / \  |_ _| \ | |
//       / _ \ | | '_ \| '_ \ / _` || ||  \| | |   | |_| | / _ \  | ||  \| |
//      / ___ \| | |_) | | | | (_| || || |\  | |___|  _  |/ ___ \ | || |\  |
//     /_/   \_\_| .__/|_| |_|\__,_|___|_| \_|\____|_| |_/_/   \_\___|_| \_|



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


contract AlphaINCHAIN is ERC721AQueryable, Ownable, ReentrancyGuard {
    using Strings for uint256;
    using ECDSA for bytes32;
    //@dev adjust these values for your collection
    uint public maxSupply = 10000;

    uint public wlMintCounter = 0;
    uint public maxWL = 1000;

    uint public vipMintCounter = 0;
    uint public maxVipMints = 1000;

    uint public publicPrice = 0.1 ether;
    uint public whitelistPrice = 0.1 ether;
    uint public vipPrice = 0.1 ether;

    uint public maxPublicMints = 10;

    //@dev byte-pack bools and address to save gas
    bool publicSaleStarted = false;
    bool whiteListStarted = false;
    bool vipStarted = true;

    /*@dev Reference Address to Compare ECDSA Signature
    Fill this in with your own WL Address
    To learn more about signatures check out
    https://docs.ethers.io/v5/api/signer/#:~:text=A%20Signer%20in%20ethers%20is,on%20the%20sub%2Dclass%20used.*/
    address private whitelistAddress = 0x5F26BdA8d2Fc55A8e3ef34c4b29ac7e0e20Cec29;
    address private vipAddress = 0x94BAeb39831BE12Ec109ed8dC8Df45fe9605F92e;
    address private payoutAddress = 0xD1854e17DAB6e3eCEA54463EF972707F42d04a11;


    /* @dev Used in TokenURI Function for exchanges.
        For more information about this standard check out
        https://docs.opensea.io/docs/metadata-standards
    */
    string public baseURI = "https://api.alphainchain.io/v1/nft/metadata/";
    string public uriSuffix = ".json";


    // @dev these mappings track how many one has minted on public and WL respectively
    mapping(address => uint) public publicMints;
    mapping(address => uint) public wlMints;
    mapping(address => uint) public vipMints;
    //This is where the staking contract will be stored.

    constructor()
    ERC721A("AlphaINCHAIN", "AIC")
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

    //END SIGNATURE VERIFICATION


    /* MINTING */

    //@dev minting function for public sale
    function publicMint(uint amount) external payable {
        if (!publicSaleStarted) revert SaleNotStarted();
        if (totalSupply() + amount > maxSupply) revert SoldOut();
        if (publicMints[_msgSender()] + amount > maxPublicMints) revert MaxMints();
        if (msg.value < amount * publicPrice) revert ValueTooLow();

        publicMints[_msgSender()] += amount;
        _mint(msg.sender, amount);

        uint payout = amount * publicPrice;
        (bool os,) = payable(payoutAddress).call{value : payout}("");

    }

    //@dev The Max Someone Can Mint is Encoded In The Signature. Be careful
    function vipMint(uint amount, uint max, bytes memory signature) external payable {
        if (!vipStarted) revert SaleNotStarted();
        if (totalSupply() + amount > maxSupply) revert SoldOut();
        if (vipMintCounter + amount > maxVipMints) revert RoundSoldOut();
        if (vipMints[_msgSender()] + amount > max) revert MaxMints();
        if (!verifyAddressSigner(vipAddress, hashMessage(max, msg.sender), signature)) revert NotWL();
        if (msg.value < amount * vipPrice) revert ValueTooLow();

        vipMints[_msgSender()] += amount;
        vipMintCounter += amount;
        _mint(_msgSender(), amount);

        uint payout = amount * vipPrice;
        (bool os,) = payable(payoutAddress).call{value : payout}("");
    }


    //@dev The Max Someone Can Mint is Encoded In The Signature. Be careful
    function whiteListMint(uint amount, uint max, bytes memory signature) external payable {

        if (!whiteListStarted) revert SaleNotStarted();
        if (totalSupply() + amount > maxSupply) revert SoldOut();
        if (wlMintCounter + amount > maxWL) revert RoundSoldOut();
        if (!verifyAddressSigner(whitelistAddress, hashMessage(max, msg.sender), signature)) revert NotWL();
        if (msg.value < amount * whitelistPrice) revert ValueTooLow();
        if (wlMints[_msgSender()] + amount > max) revert MaxMints();


        wlMints[msg.sender] += amount;
        wlMintCounter += amount;
        _mint(msg.sender, amount);

        uint payout = amount * whitelistPrice;
        (bool os,) = payable(payoutAddress).call{value : payout}("");

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

    function setPayoutAddress(address _newAddress) external onlyOwner {
        require(_newAddress != address(0), "CAN'T PUT 0 ADDRESS");
        payoutAddress = _newAddress;
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

    function setVipPrice(uint64 _newPrice) external onlyOwner {
        vipPrice = _newPrice;
    }

    function setWlSupply(uint16 _wlSupply) external onlyOwner {
        require(_wlSupply <= maxSupply, "Cant Increase Size Of Collection");
        maxWL = _wlSupply;
    }

    function setMaxVipSupply(uint16 _wlSupply) external onlyOwner {
        require(_wlSupply <= maxSupply, "Cant Increase Size Of Collection");
        maxVipMints = _wlSupply;
    }

    function setMaxSupply(uint newSupply) external onlyOwner {
        require(newSupply <= maxSupply, "Cant Increase Size Of Collection");
        maxSupply = newSupply;
    }

    function setMaxPublicMints(uint amount) external onlyOwner {
        maxPublicMints = amount;
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