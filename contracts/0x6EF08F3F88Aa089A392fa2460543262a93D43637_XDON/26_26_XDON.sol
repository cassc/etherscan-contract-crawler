// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./@layerzerolabs/solidity-examples/contracts/token/onft/ONFT721.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol"; // OZ: MerkleProof
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract XDON is ONFT721 {
    using Strings for uint256;
    uint public nextMintId;
    uint public maxMintId;
    uint public whitelistStartPeriod;
    uint public whitelistEndPeriod;
    bytes32 public immutable merkleRoot;
    mapping(address => uint) public userMints;
    uint public mintPrice;
    uint public publicMintLimit = 2;
    uint public whitelistedInitialLimit = 2;
    uint public whitelistedMintLimit;

    address public treasure;
    bool public mintHalted = false;
    string baseURI_;

    error InvalidMintStartId();
    error InvalidMaxMint();
    error MintPeriodNotStarted();
    error MintPeriodEnded();
    error InvalidMintDates();
    error MaxMintReached();
    error AlreadyClaimed();
    error InvalidProof();
    error SetMintPriceInvalid();
    error SetTreasureInvalid();
    error InvalidPaymentTransfer();
    error MaxAllowedForPublic();
    error PublicMintNotStarted();
    error MaxAllowedForWhitelisted();
    error InvalidMintPayment();
    error MintingByContractNotAllowed();
    error InvalidMintPrice();
    error InvalidTreasureAddress();
    error MintHalted();

    event NewPrice(uint price);
    event NewLimits(uint _public, uint _whitelisted, uint _wlInitial);
    event MintPeriod(uint _public, uint _whitelisted);

    constructor(
        uint _minGasToTransfer, address _layerZeroEndpoint,
        uint _startMintId, uint _maxMintId,
        uint _whitelistStartPeriod, uint _whitelistEndPeriod,
        bytes32 _merkleRoot, uint _mintPrice, address _treasure )
    ONFT721("Xexadons", "XDON", _minGasToTransfer, _layerZeroEndpoint)
    {
        if( _startMintId == 0)
            revert InvalidMintStartId();

        if (_maxMintId == 0)
            revert InvalidMaxMint();

        if (_whitelistStartPeriod == 0 || _whitelistEndPeriod == 0 || _whitelistStartPeriod >= _whitelistEndPeriod)
            revert InvalidMintDates();

        if( _mintPrice == 0 )
            revert InvalidMintPrice();

        if( _treasure == address(0) )
            revert InvalidTreasureAddress();

        mintPrice = _mintPrice;

        whitelistStartPeriod = _whitelistStartPeriod;
        whitelistEndPeriod = _whitelistEndPeriod;

        nextMintId = _startMintId;
        maxMintId = _maxMintId;

        merkleRoot = _merkleRoot;

        treasure = _treasure;

        emit NewPrice(mintPrice);

        whitelistedMintLimit = publicMintLimit + whitelistedInitialLimit;

        emit NewLimits(publicMintLimit, whitelistedMintLimit, whitelistedInitialLimit);

        emit MintPeriod(whitelistStartPeriod, whitelistEndPeriod);

    }

    function contractURI() public view returns (string memory) {
        return "https://xexadons.com/contract.json";
    }

    function haltMint() external onlyOwner{
        mintHalted = true;
    }

    function setMintLimits(uint _public, uint _whitelistedInitialLimit) external onlyOwner {
        publicMintLimit = _public;
        whitelistedInitialLimit = _whitelistedInitialLimit;
        whitelistedMintLimit = publicMintLimit + whitelistedInitialLimit;

        emit NewLimits(publicMintLimit, whitelistedMintLimit, _whitelistedInitialLimit);
    }

    function setMintPeriods(uint _start, uint _end) external onlyOwner {
        whitelistStartPeriod = _start;
        whitelistEndPeriod = _end;
        emit MintPeriod(whitelistStartPeriod, whitelistEndPeriod);
    }

    function setMintPrice(uint _price) external onlyOwner {
        if (_price == 0)
            revert SetMintPriceInvalid();
        mintPrice = _price;
        emit NewPrice(mintPrice);
    }

    function setTreasure(address _treasure) external onlyOwner {
        if( _treasure == address(0) )
            revert SetTreasureInvalid();
        treasure = _treasure;
    }

    function tokenURI(uint tokenId) public view override returns (string memory) {
        return bytes(baseURI_).length > 0 ?
            string(abi.encodePacked(baseURI_, tokenId.toString(), ".json")) :
            "https://xexadons.com/xdon.json";
    }

    function setBaseURI(string memory _baseURI_) public onlyOwner {
        baseURI_ = _baseURI_;
    }

    modifier standardChecks(){
        // do not allow minting by a contract
        if( msg.sender != tx.origin ){
            revert MintingByContractNotAllowed();
        }

        // stop minting at any time, not possible to mint again
        if (mintHalted){
            revert MintHalted();
        }

        // prevent minting before mint period start
        if (block.timestamp < whitelistStartPeriod){
            revert MintPeriodNotStarted();
        }

        _;

    }

    function checkProof(bytes32[] memory proof) public view returns(bool){
        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(msg.sender, block.chainid))));
        return MerkleProof.verify(proof, merkleRoot, leaf);
    }

    function claim(bytes32[] memory proof) external payable standardChecks {


        // check if we are inside whitelist mint period
        if (block.timestamp > whitelistEndPeriod) {
            revert MintPeriodEnded();
        }

        // user must be in the whitelist for this chain.
        if (!checkProof(proof)){
            revert InvalidProof();
        }

        // each whitelisted user can mint only 1 nft
        if( userMints[msg.sender] >= whitelistedInitialLimit ){
            revert MaxAllowedForWhitelisted();
        }


        uint newId = nextMintId;
        // check if we reached the max mint for this chain
        if (nextMintId > maxMintId){
            revert MaxMintReached();
        }

        nextMintId++;
        userMints[msg.sender]++;

        _safeMint(msg.sender, newId);

        // check if user is correctly paying for this mint
        if( msg.value < mintPrice ){
            revert InvalidMintPayment();
        }

        (bool paymentValid, ) = payable(treasure).call{value: address(this).balance}("");

        // revert if sending funds to treasure return error
        if( ! paymentValid ){
            revert InvalidPaymentTransfer();
        }

    }

    function mint( bytes32[] memory proof ) external payable standardChecks {

        // above whitelist mint period, user can mint up to 2 nft
        if( block.timestamp < whitelistEndPeriod ){
            revert PublicMintNotStarted();
        }

        if ( checkProof(proof) ){
            // if user is whitelisted he can mint:
            // - 1 from whitelist
            // - 1 from public mint
            if( userMints[msg.sender] >= whitelistedMintLimit ){
                revert MaxAllowedForWhitelisted();
            }
        }else{
            // if not invalid proof, user can mint only 1
            if( userMints[msg.sender] >= publicMintLimit ){
                revert MaxAllowedForPublic();
            }
        }

        uint newId = nextMintId;
        nextMintId++;

        // check if we reached the max mint for this chain
        if (nextMintId > maxMintId){
            revert MaxMintReached();
        }

        userMints[msg.sender]++;
        _safeMint(msg.sender, newId);

        // check if user is correctly paying for this mint
        if( msg.value < mintPrice ){
            revert InvalidMintPayment();
        }

        (bool paymentValid, ) = payable(treasure).call{value: address(this).balance}("");

        // revert if sending funds to treasure return error
        if( ! paymentValid ){
            revert InvalidPaymentTransfer();
        }

    }

}