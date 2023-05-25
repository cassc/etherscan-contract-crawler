// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import {UpdatableOperatorFilterer} from "operator-filter-registry/src/UpdatableOperatorFilterer.sol";
import {RevokableDefaultOperatorFilterer} from "operator-filter-registry/src/RevokableDefaultOperatorFilterer.sol";

contract ARC is ERC721A, Ownable, RevokableDefaultOperatorFilterer, ReentrancyGuard {

    enum MintType { ATARI50CLAIM, ATARISETCLAIM, PARTNER, PUBLIC }
    event mintToken(address wallet, uint256 tokenId, uint256 tokenType);

    mapping(MintType => uint256) private mintCost;
    mapping(MintType => bool) private mintActive;
    mapping(MintType => uint256) private maxMint;

    address public futureBurnContract;
    address private signer = 0x2f2A13462f6d4aF64954ee84641D265932849b64;

    string public _metadata = "https://ataripublic.s3.amazonaws.com/metadata/";
    bool private metadataSwitch = true;

    uint256 constant MAX_SUPPLY = 2600;

    bool public burnActive = false;

    mapping(MintType => uint256) public tokenTypeToMinted;
    mapping(uint16 => MintType) public tokenToId;

    mapping(MintType => mapping(address => bool)) public walletMintedTokenType;

    constructor() ERC721A("Atari Redemption Certificate", "ARC")  {
        mintCost[MintType.ATARI50CLAIM] = 0 ether;
        mintCost[MintType.ATARISETCLAIM] = 0 ether;
        mintCost[MintType.PARTNER] = 0.08 ether;
        mintCost[MintType.PUBLIC] = 0.08 ether;

        mintActive[MintType.ATARI50CLAIM] = false;
        mintActive[MintType.ATARISETCLAIM] = false;
        mintActive[MintType.PARTNER] = false;
        mintActive[MintType.PUBLIC] = false;

        maxMint[MintType.ATARI50CLAIM] = 1282;
        maxMint[MintType.ATARISETCLAIM] = 18;
        maxMint[MintType.PARTNER] = 1300;
    }

    function mint(bytes calldata _voucher, MintType mintType) external payable nonReentrant {

        uint256 costPerMint = mintCost[mintType];
        uint256 maxMintForToken = maxMint[mintType];

        //Mint active also guards against non existant mint type.
        require(mintActive[mintType], "Mint type not active");

        require(msg.sender == tx.origin, "EOA only");

        //Supply checks
        require(_totalMinted() + 1 <= MAX_SUPPLY, "Minted out");

        //check if minted allowlist
        require(!walletMintedTokenType[mintType][msg.sender], "Already claimed tokens");

        walletMintedTokenType[mintType][msg.sender] = true;

        if(mintType != MintType.PUBLIC) {
            require(tokenTypeToMinted[mintType] + 1 <= maxMintForToken, "This type is minted out for");

            bytes32 hash = keccak256(abi.encodePacked(msg.sender, uint8(mintType)));
            require(_verifySignature(signer, hash, _voucher), "Invalid voucher");
        }

        require(msg.value >= costPerMint, "Ether value sent is not correct");
        
        tokenTypeToMinted[mintType] += 1;

        _mintTokens(msg.sender, mintType);
    }

    function mintAdmin(address wallet, uint256 amount, MintType typeOfMint) external payable nonReentrant onlyOwner {
        require(_totalMinted() + amount <= MAX_SUPPLY, "Minted out");

        require(tokenTypeToMinted[typeOfMint] + amount <= maxMint[typeOfMint], "This type is minted out for");

        tokenTypeToMinted[typeOfMint] += amount;

        for(uint256 i = 0; i < amount; i++)
            _mintTokens(wallet, typeOfMint);

    }


    function _mintTokens(address _wallet, MintType _tokenType) internal {
        uint16 tokenId = uint16(_totalMinted());

        tokenToId[tokenId] = _tokenType;

        _mint(_wallet, 1);
    }

    function _verifySignature(address _signer, bytes32 _hash, bytes memory _signature) internal pure returns (bool) {
        return _signer == ECDSA.recover(ECDSA.toEthSignedMessageHash(_hash), _signature);
    }

    function setSigner(address _signer) external onlyOwner {
        signer = _signer;
    }

    function burn(uint256 tokenId) external  {
        require(burnActive, "Burn is not active");
        require(msg.sender == futureBurnContract, "Must be from future burn contract");

        _burn(tokenId, false);        
    }

    function setApprovalForAll(
        address operator,
        bool approved
    ) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(
        address operator,
        uint256 tokenId
    ) public payable override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function _baseURI() internal view virtual override returns(string memory) {
        return _metadata;
    }

    function setMetadata(string memory metadata) public onlyOwner {
        _metadata = metadata;
    }

    function setBurnActive() public onlyOwner {
        burnActive = !burnActive;
    }

    function setMintActive(MintType mintType, bool state) public onlyOwner {
        mintActive[mintType] = state;
    }

    function setMintCost(MintType mintType, uint256 newCost) public onlyOwner {
        mintCost[mintType] = newCost;
    }

    function setMaxMint(MintType mintType, uint256 newMax) public onlyOwner {
        maxMint[mintType] = newMax;
    }

    function setMetadataSwitch() public onlyOwner {
        metadataSwitch = !metadataSwitch;
    }

    function setFutureBurnContract(address _contract) public onlyOwner {
        futureBurnContract = _contract;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        string memory baseURI = _baseURI();

        if(metadataSwitch) {

            MintType tokentype = tokenToId[uint16(tokenId)];
            uint8 mintType = uint8(tokentype);


            return string(abi.encodePacked(baseURI, Strings.toString(mintType), "/", Strings.toString(tokenId)));

        }
        
        return string(abi.encodePacked(baseURI, Strings.toString(tokenId)));

	}

    function withdraw() public payable onlyOwner {
        (bool success, ) = payable(msg.sender).call {value: address(this).balance}("");
        require(success);
    }

    function getAmountMintedPerType(MintType mintType, address _address) public view returns (bool) {
        return walletMintedTokenType[mintType][_address];
    }

    function owner() public view override(Ownable, UpdatableOperatorFilterer) returns (address) {
        return Ownable.owner();
    }

    //19c3s1a13c19j14b50e0
}