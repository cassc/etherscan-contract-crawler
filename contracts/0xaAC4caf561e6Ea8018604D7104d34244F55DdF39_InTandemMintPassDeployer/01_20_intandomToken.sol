// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./intandemERC1155.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";


abstract contract RedeemerContractI {
    function redeemIntandemToken(uint256 _tokenId , uint256 _amount, address Tokenowner) public virtual;
}

contract InTandemMintPassDeployer is IntandemERC1155 {
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private mtCounter;
    mapping(uint256 => MintToken) public mintTokens;
    mapping(string => address) public address_coupon_map;
    bytes32 public merkleRootHash = 0x1d59a72f85142a530d352a30071dedab0bc31ac19923881855f8badd5d836313;
    uint8 public whitelist_check = 1;
    mapping (address => uint8) redeem_to;
    uint256 public mint_price = 0.2 ether;

    event Claimed(uint index, address indexed account, uint amount, string coupon);
    event TokenAddedToMint(uint256 tokenID, string identifyingSerialNumber);
    event TokenRedeemed(uint256 tokenId, address TokenOwner, address redeemTo);

    error invalidToken();
    error ZeroAddress();
    error EmptyUri();
    error TokenNotExist();
    error ClaimParamWrong();
    error AirdropToNull();
    error AirdropZeroAmount();
    error AlreadyMinted();
    error CouponRedeemed();
    error MaxSupplyReached();
    error ZeroMaxSupply();
    error InvalidMaxSupply();
    error InvalidWhitelistCheck();
    error InvalidMintPerTransLimit();
    error MintPerTransLimitReached();
    error InvalidRedeem();
    error InvalidPrice(uint256 _price);

    constructor(address _admin, string memory _firstTokenURI, uint256 _firstTokenMaxSupply) ERC1155("https://base_uri/"){
        name_ = "InTandem Mint Pass";
        symbol_ = "INT";
        mtCounter.increment();
        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
        addMintToken(_firstTokenURI, _firstTokenMaxSupply, 1);
    }

    function addMintToken(
        string memory _ipfsMetadataLink,
        uint256 _maxSupply,
        uint256 _mintPerTransactionLimit
    ) public onlyAdmin {
        if (_maxSupply == 0) revert ZeroMaxSupply();
        uint256 _tokenIndex = mtCounter.current();
        MintToken storage mt = mintTokens[_tokenIndex];
        _update_mt(mt, _ipfsMetadataLink, _maxSupply, _mintPerTransactionLimit);
        mtCounter.increment();
        emit TokenAddedToMint(_tokenIndex, _ipfsMetadataLink);
    }

    function _update_mt(
        MintToken storage mt,
        string memory _ipfsMetadataLink,
        uint256 _maxSupply,
        uint256 _mintPerTransLimit
    ) internal {
        if (bytes(_ipfsMetadataLink).length == 0) {
            revert EmptyUri();
        }

        mt.ipfsMetadataLink = _ipfsMetadataLink;
        mt.maxSupply = _maxSupply;
        mt.mintPerTransLimit = _mintPerTransLimit;
    }

    function editMintToken(
        uint256 _tokenIndex,
        string memory _ipfsMetadataLink,
        uint256 _maxSupply,
        uint256 _mintPerTransLimit
    ) external onlyAdmin {
        if (!(_tokenIndex > 0 && _tokenIndex < mtCounter.current())) revert TokenNotExist();
        if (_maxSupply == 0) revert ZeroMaxSupply();
        if (_maxSupply < totalSupply(_tokenIndex)) revert InvalidMaxSupply();
        if (_mintPerTransLimit > _maxSupply) revert InvalidMintPerTransLimit();

        _update_mt(mintTokens[_tokenIndex], _ipfsMetadataLink, _maxSupply, _mintPerTransLimit);
    }

    function claim(
        uint256 numTokens,
        uint256 _tokenIndexToMint,
        string memory _coupon,
        bytes32[] calldata _proof
    ) external payable{
        require(isValidClaim(numTokens, _tokenIndexToMint, _coupon, _proof));
        mintTokens[_tokenIndexToMint].claimedMTs[msg.sender] = mintTokens[_tokenIndexToMint].claimedMTs[msg.sender].add(numTokens);
        mintTokens[_tokenIndexToMint].mintedCount = mintTokens[_tokenIndexToMint].mintedCount.add(numTokens);

        if (isAdmin() == 0 && whitelist_check == 1){
            address_coupon_map[_coupon] = msg.sender;
        }
        emit Claimed(_tokenIndexToMint, msg.sender, numTokens, _coupon);
        _mint(msg.sender, _tokenIndexToMint, numTokens, "");
    }

    function isValidClaim(
        uint256 numTokens, uint256 _tokenIndexToMint, string memory _coupon,
        bytes32[] calldata _proof) internal view returns (bool) {
        if (!(_tokenIndexToMint > 0 && _tokenIndexToMint < mtCounter.current())) revert TokenNotExist();
        if (!(mintTokens[_tokenIndexToMint].mintPerTransLimit >= numTokens)) revert MintPerTransLimitReached();
        if (!(mintTokens[_tokenIndexToMint].claimedMTs[msg.sender] == 0)) revert AlreadyMinted();
        if (!(mintTokens[_tokenIndexToMint].maxSupply >= totalSupply(_tokenIndexToMint).add(numTokens))) revert MaxSupplyReached();
        if (msg.value < mint_price) revert InvalidPrice(msg.value);
        if (isAdmin() == 0 && whitelist_check == 1) {
            if (address_coupon_map[_coupon] != address(0)) revert CouponRedeemed();
            bytes32 leaf = keccak256(abi.encodePacked(_coupon));
            if (!(MerkleProof.verify(_proof, merkleRootHash, leaf))) {
                revert ClaimParamWrong();
            }
        }
        return true;
    }

    function uri(uint256 _id) public view override returns (string memory) {
        if (!(_id < mtCounter.current() && _id > 0)) revert TokenNotExist();
        return mintTokens[_id].ipfsMetadataLink;
    }

    function airdrop(uint _tokenID, uint _amount, address _addr) external onlyOwner {
        if (_addr == address(0)) revert AirdropToNull();
        if (!(_tokenID > 0 && _tokenID < mtCounter.current())) revert TokenNotExist();
        if (!(_amount > 0)) revert AirdropZeroAmount();
        mintTokens[_tokenID].claimedMTs[msg.sender] = mintTokens[_tokenID].claimedMTs[msg.sender].add(_amount);
        mintTokens[_tokenID].mintedCount = mintTokens[_tokenID].mintedCount.add(_amount);
        _mint(_addr, _tokenID, _amount, "");
    }

    function setWhitelistCheck(uint8 _whitelistCheck) external onlyAdmin {
        if (_whitelistCheck > 1) revert InvalidWhitelistCheck();
        whitelist_check = _whitelistCheck;
    }

    function setMintPerTransLimit(uint256 _tokenIndex, uint256 _mintPerTransLimit) external onlyAdmin {
        if (!(_tokenIndex > 0 && _tokenIndex < mtCounter.current())) revert TokenNotExist();
        if (mintTokens[_tokenIndex].maxSupply < _mintPerTransLimit) revert InvalidMintPerTransLimit();
        mintTokens[_tokenIndex].mintPerTransLimit = _mintPerTransLimit;
    }

    function setMerkleRootHash(bytes32 _rootHash) external onlyAdmin{
        merkleRootHash = _rootHash;
    }

    function setRedeemTo(address _redeem_to_address) external onlyAdmin{
        if(_redeem_to_address==address(0)) revert ZeroAddress();
        redeem_to[_redeem_to_address] = 1;
        
    }

    function redeem(uint256 _tokenId, uint256 _amount, address _to) external {
        if (!(_tokenId > 0 && _tokenId < mtCounter.current())) revert TokenNotExist();
        if(redeem_to[_to]==0) revert InvalidRedeem();
        if(_amount==0) revert InvalidRedeem();
        RedeemerContractI redeemerContract = RedeemerContractI(_to);
        redeemerContract.redeemIntandemToken(_tokenId, _amount, msg.sender);
        emit TokenRedeemed(_tokenId, msg.sender, _to);
        burn(msg.sender, _tokenId, _amount);
    }

    function setMintprice(uint256 _new_price) external onlyAdmin{
        if(_new_price ==0) revert InvalidPrice(_new_price);
        mint_price = _new_price;
    }

}