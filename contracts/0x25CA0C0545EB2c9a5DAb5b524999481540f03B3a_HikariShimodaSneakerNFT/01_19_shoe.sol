// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "hardhat/console.sol";

contract HikariShimodaSneakerNFT is EIP712, ERC721, AccessControl, Ownable, ERC721Burnable  {

    // metadata base uri
    string private baseUri_ = "ipfs://bafybeidzcmzpruznkn434woid2rtisxmtm45kfgqmv2gw2wur5uwdiywda/"; 

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    // total supply
    uint256 private totalSupply_ = 2200;

    // max public mint allowance is 10
    uint256 private maxMint_ = 10;
    
    // max pre mint allowance is 3
    uint256 private maxPremint_ = 3;

    // check if public sale has satarted
    bool private saleStarted_ = false;

    // check if private sale has satarted
    bool private preSaleStarted_ = false;

    // check if free mint has satarted
    bool private freeMintStarted_ = false;

    // payment receiver address
    address private receiver_;

    // sneaker price
    uint256 public sneakerPrice_ = 120000000000000000; // 0.12 ETH

    // owner NFT count (for public sale)
    mapping(address => uint256) public ownerTokenCount;

    // owner NFT count (for private sale)
    mapping(address => uint256) public ownerTokenCountPremint;
    
    // Whether freemint allowance is used for a given account
    mapping(address => bool) public freeMintUsed;

    // Free mint list with allowance
    mapping(address => uint256) public freeMintAllowance;

    // keep track of current token id, increment when user mint
    uint public currentTokenId = 0;

    event HikariShimodaSneakerMinted(uint256 indexed tokenId);

    constructor(string memory name, string memory symbol, address receiver) 
    EIP712(name, "1.0.0")
    ERC721(name, symbol) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, _msgSender());
        receiver_ = receiver;
        initFreeMintAllowance();
    }

    // Init allowance mapping
    function initFreeMintAllowance() internal {
        freeMintAllowance[0xC52650d88793Cf5fc0295BEE9aE49284e67fEcB1] = 22;
        freeMintAllowance[0x9D2B0251D366CE712E75048204C005Fd63394F46] = 5;
        freeMintAllowance[0xc24F574D6853F6F6A31C19D468A8C1b3f31c0E54] = 5;
        freeMintAllowance[0x0e94af7a715274345BccF9996F98F145d3Ca1499] = 3;
        freeMintAllowance[0xE113E7B1E8Ecd07973EA40978aED520241d17f27] = 3;
        freeMintAllowance[0x6FeC474030a273A673DfF02F83BB1cEb9de7b82c] = 2;
        freeMintAllowance[0x1CF2B8c64AEd32bFf2Ae80e701681316d3212aFd] = 2;
        freeMintAllowance[0x73E4a2B60Cf48E8BaF2B777E175a5B1E4D0C2d8f] = 2;
        freeMintAllowance[0x7E23a0a9fD1105ca4b1DC9B7E0F0AAb3b7071Caa] = 2;
        freeMintAllowance[0xB890F264b1A7591cdF9e21B3B640A741CF677AE9] = 2;
        freeMintAllowance[0xCE7A9F981a2a79C79340297EDFf7BB6B73f71913] = 2;
        freeMintAllowance[0x2d1bdC590Cb736097Bc5577c8974e28dc48F5ECc] = 1;
        freeMintAllowance[0x2e0C34490a9eE70AF5404BB7BBdB489FB3D99487] = 1;
        freeMintAllowance[0x2E0D63fFCB08eA20fF3AcDbB72dfEc97343885d2] = 1;
        freeMintAllowance[0x41497f8b5f70771A471aB9dBE0136d8B8F8518f7] = 1;
        freeMintAllowance[0x4874211da929DD87E28a4267c4B96a5D0ccf48a7] = 1;
        freeMintAllowance[0x4Dd91f366E1Ffc6BfC88A9d2aF682093C9E24b0F] = 1;
        freeMintAllowance[0x507Bd0790feBc870bd1eb27e21Cf8a05Bf740e4a] = 1;
        freeMintAllowance[0x52aD8f3C506aA25b954276c5456060DAd6f3Fd7b] = 1;
        freeMintAllowance[0x55013e79Dc8fB573588B22447633c049e13ff1f3] = 1;
        freeMintAllowance[0x569Bf4dDEB2988F44ee99C968DcDA6F60be58260] = 1;
        freeMintAllowance[0x606cCA7f81b53C94cA321FFC122f0019b26cf7C0] = 1;
        freeMintAllowance[0x6b4331048c411795a89D54484E3653107D58a64E] = 1;
        freeMintAllowance[0x704c978d50590B21E4c2F43eb4dA24fe61FCD707] = 1;
        freeMintAllowance[0x728f2548559E2AaCAE8B6b01FC39fF72771FF8BE] = 1;
        freeMintAllowance[0x72c6C6310535EdBD273957D476c4c4f721b9226A] = 1;
        freeMintAllowance[0x735a4c94c506B694dE3a87A5C5eeB35C2D26d966] = 1;
        freeMintAllowance[0x01C2e7b1de06DA53Bd0EC82fdB59E5767b8c6dA1] = 1;
        freeMintAllowance[0x74F3bD4D3bFe3B589C3Bb151b46B6ad2d0c4a101] = 1;
        freeMintAllowance[0x7971e007A4E4D4dc1F8380f5d91d3F52B5e53461] = 1;
        freeMintAllowance[0x19A0110537e4960c765D6f3Fea9445b022A287f0] = 1;
        freeMintAllowance[0x88dA36152D4691e8D4EFc998DDb7B22Fe1B16898] = 1;
        freeMintAllowance[0x8a0A569B2937ecC360a686386E34dF83CD2348a3] = 1;
        freeMintAllowance[0x8D3caf6B8630038eEc261646a53476402C8fc739] = 1;
        freeMintAllowance[0x90238A0A150C47e326A19AD38f05700021fCfa62] = 1;
        freeMintAllowance[0x92Ed9731D907bcbeE5E792eF3960E2612b1577a5] = 1;
        freeMintAllowance[0x94de7E2c73529EbF3206Aa3459e699fbCdfCD49b] = 1;
        freeMintAllowance[0x1B2965dC3B1697DD10b7126EC7393d79cdA2cF91] = 1;
        freeMintAllowance[0xA00C78Fc1eDb8F9C91637722041dbA67Af32Bb22] = 1;
        freeMintAllowance[0xabb20917a30d3330839E20432fb6C656390b8a52] = 1;
        freeMintAllowance[0xAe48F64abeaA92618b8180c0FD33CAEBfEd42f2b] = 1;
        freeMintAllowance[0x1F92fC15bCbEB4dD24EeFbead8d7aeE409f891DC] = 1;
        freeMintAllowance[0x234E486279dC07733E5dB157277910Bd6002D3f0] = 1;
        freeMintAllowance[0x2423B65C54bcf69633752C388185C431Da74DbBa] = 1;
        freeMintAllowance[0xCedec45e06cBB9032625830C5FFB0CF3fAD1cF67] = 1;
        freeMintAllowance[0xd76Aa530b8C1F0039971Eca13ca1850047271aF0] = 1;
        freeMintAllowance[0xdb1Cf642C4299ef486baAE9cE15a66F9F8d6ACC0] = 1;
        freeMintAllowance[0x26439aEB008d63B6686798b5F08a84C7AbeFbd80] = 1;
        freeMintAllowance[0xE48ab528F2B51Fa68E22d57069CfFaFCd4aA2b6C] = 1;
        freeMintAllowance[0xEc7641e298aF02c19171451381C570327389b0c2] = 1;
        freeMintAllowance[0xf7a69901D4AC776e7347f9fC6c4a671354157Df4] = 1;
        freeMintAllowance[0xf7A8f04C7fE7C8A6ED692Bdf5EE1658559cbE7Dc] = 1;
        freeMintAllowance[0xf868a2DE45bc38844B16C9e63FdA5E1DE1d54A22] = 1;
        freeMintAllowance[0x35fFC49E7FEFC188dFf81dB3c717dB098294BC23] = 1;
        freeMintAllowance[0x0f692f4a862679008BbF48CC0A7AbDFF12908f79] = 1;
        freeMintAllowance[0x2e0C34490a9eE70AF5404BB7BBdB489FB3D99487] = 1;
        freeMintAllowance[0x46ae5b30edfDe7a6f83285f8ae98A2e97C9445dd] = 1;
        freeMintAllowance[0xBBe846566F2172AdC9c0bCdCCf8D280Ad60dfa67] = 1;
        freeMintAllowance[0x3993996B09949BBA655d98C02c87EA6ABf553630] = 1;
        freeMintAllowance[0xA02113a2ed51e82B05649709FbBD4232dc11244c] = 1;
        freeMintAllowance[0xB9f5039273a63275D2f15E3C970bdbFcf47D0a5f] = 1;
        freeMintAllowance[0x594F515bcab25e2e9029AaAcf18221485Cb2f13c] = 1;
        freeMintAllowance[0xa5E0Ecb5D075e86C3bf5d1B1042e154FEe9a4798] = 1;
        freeMintAllowance[0x20bCF46a41A187d8e38a22308c801BfC3bf4714D] = 1;
        freeMintAllowance[0x2CB6be40Cda9fC0C3bCBD8c63eF92c508Ab2d6A2] = 1;
        freeMintAllowance[0xA3C277b8f35881CBdb017E52bcC376B3ce8F21dA] = 1;
        freeMintAllowance[0x49185F385b83332bda127B46e48d186083Ab4988] = 1;

        freeMintAllowance[0x2769A4Cd074e908AB8a6F94F5eb484CfaFf1c8d9] = 1;
        freeMintAllowance[0x52FAD06B1dd3f7383C6d1977D07A42003C494c02] = 1;
        freeMintAllowance[0x344F79c03B71fa1711f7661FA4A7d308e78e1841] = 1;
        freeMintAllowance[0xb7AeA3cbA4ceEf66D75902C5bd16B5C5cef058e5] = 1;
        freeMintAllowance[0x25eC5bbE2bD92E0309af09554cFBb72d1BaEbd01] = 1;
        freeMintAllowance[0xCE75584C49c4b5A3d232c16230a384497f91019E] = 1;
        freeMintAllowance[0x1cbFc9f778322D4B673cEDC8681aFeb828b4db5f] = 1;
        freeMintAllowance[0x373febCFf8CfC087B8BB2504bDb331D7b105A070] = 1;
        freeMintAllowance[0x6f315BB8EBD69BD3Fa032cc69828D1D5f7acFCd5] = 1;
        freeMintAllowance[0x246c91e1E0B7FE956AdFf1bDE151EB01C10Cd7bb] = 1;
        freeMintAllowance[0xCeD18E27D33f0457fcaf652a417fCA2281885981] = 1;
        freeMintAllowance[0x95Cef8FCe73A182aCCdfB91F3cCfC62818a7364C] = 1;
        freeMintAllowance[0xBa58f240e775f0b559eb32c38B1c54A591363Cd5] = 1;
        freeMintAllowance[0x53C371145446505932D32F76fD32aeFAD22eb11E] = 1;

        freeMintAllowance[0x05f15A393e8f2da4756316b439ee9104F2A6f2b8] = 1;
        freeMintAllowance[0x017fe812Df7Bea272511A47955099a9E8D20282E] = 2;
        freeMintAllowance[0x15eB66B35586F94a1dF04850ebAb49560A1C07ff] = 20;
    }

    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

    // update public sale status
    function updateSaleStatus(bool status) external onlyOwner {
        saleStarted_ = status;
    }

    // update private sale status
    function updatePreSaleStatus(bool status) external onlyOwner {
        preSaleStarted_ = status;
    }

    // update freemint status
    function updateFreeMintStatus(bool status) external onlyOwner {
        freeMintStarted_ = status;
    }

    // update sneaker price
    function updateSneakerPrice(uint256 sneakerPrice) external onlyOwner {
        sneakerPrice_ = sneakerPrice;
    }

    // update max mint for public sale
    function updateMaxMint(uint256 maxMint) external onlyOwner {
        maxMint_ = maxMint;
    }

    // update payment receiver address
    function updateReceiver(address receiver) external onlyOwner {
        receiver_ = receiver;
    }

    // update metadata base uri
    function updateBaseUri(string memory uri) external onlyOwner {
        baseUri_ = uri;
    }

    // update freemint mapping 
    function updateFreeMintMapping(address freeMintAddress, uint256 allowance) external onlyOwner {
        // if the record does exist, update the address with the new allowance
        // allowance 0 means the account is not eligible for the freemint
        freeMintAllowance[freeMintAddress] = allowance;
    }

    function _baseURI() internal view override virtual returns (string memory) {
        return baseUri_;
    }

    // mint function for public sale
    function mint(uint number) public payable {
        require(saleStarted_ == true, "The sale has not started yet");
        require(msg.value >= number * sneakerPrice_, "Transaction amount not enough");
        require(number <= maxMint_, "Max 10 mint per account during the public sale");
        require((ownerTokenCount[msg.sender] + number) <= maxMint_, "Max 10 mint per account during the public sale");
        require(currentTokenId + number <= totalSupply_, "Collection sold out");

        payable(receiver_).transfer(msg.value);
        for (uint i=0; i<number; i++) {
            _safeMint(msg.sender, currentTokenId);
            ownerTokenCount[msg.sender] += 1;
            emit HikariShimodaSneakerMinted(currentTokenId);
            currentTokenId += 1;
        }
    }

    function preMint(bytes calldata signature, uint number) public payable {
        // 7777 is the special code for pre-mint
        require(_verify(_hash(msg.sender, 7777), signature), "You are not in the whitelist for pre-mint");
        require(preSaleStarted_ == true, "The pre-sale has not started yet");
        require(msg.value >= number * sneakerPrice_, "Transaction amount not enough");
        require(number <= maxPremint_, "Max 3 mint per account during the premint period");
        require((ownerTokenCountPremint[msg.sender] + number) <= maxPremint_, "Max 3 mint per account during the premint period");
        require(currentTokenId + number <= totalSupply_, "Collection sold out");

        payable(receiver_).transfer(msg.value);
        for (uint i=0; i<number; i++) {
            _safeMint(msg.sender, currentTokenId);
            ownerTokenCountPremint[msg.sender] += 1;
            emit HikariShimodaSneakerMinted(currentTokenId);
            currentTokenId += 1;
        }
    }
    
    function freeMint() external {
        require(freeMintStarted_ == true, "The free mint period has not started yet");
        require(freeMintUsed[msg.sender] == false, "You have already minted for free");
        uint256 allowance = freeMintAllowance[msg.sender];
        require(allowance > 0, "You are not in the whitelist for free mint");
        require(currentTokenId + allowance <= totalSupply_, "Collection sold out");

        for (uint i=0; i<allowance; i++) {
           _safeMint(msg.sender, currentTokenId);
            ownerTokenCount[msg.sender] += 1;
            emit HikariShimodaSneakerMinted(currentTokenId);
            currentTokenId += 1;
        }
        freeMintUsed[msg.sender] = true;
    }

    // owner can mint for a given account to help user who transferred ETH but didn't receive NFT
    function mintByOwner(address account) external onlyOwner {
        require(currentTokenId + 1 < totalSupply_, "Collection sold out");
        _safeMint(account, currentTokenId);
        ownerTokenCount[account] += 1;
        emit HikariShimodaSneakerMinted(currentTokenId);
        currentTokenId += 1;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControl, ERC721) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
    
    function _hash(address account, uint256 mintType)
    internal view returns (bytes32)
    {
        // no space between parameters!!
        return _hashTypedDataV4(keccak256(abi.encode(
            keccak256("NFT(address account,uint256 mintType)"),
            account,
            mintType
        )));
    }

    function _verify(bytes32 digest, bytes memory signature)
    internal view returns (bool)
    {
        return hasRole(MINTER_ROLE, ECDSA.recover(digest, signature));
    }
    
    function decodedAddress(address account, uint256 mintType, bytes calldata signature) external view returns (address) 
    {
        return ECDSA.recover(_hash(account, mintType), signature);
    }
}