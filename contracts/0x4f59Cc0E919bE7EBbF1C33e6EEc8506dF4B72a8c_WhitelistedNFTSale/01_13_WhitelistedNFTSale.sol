// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

import "./interfaces/IMeritMintableNFT.sol";

contract WhitelistedNFTSale is AccessControlEnumerable {

    error ZeroMintError();
    error SaleNotStartedError();
    error SaleEndedError();
    error InsufficientETHError();
    error MerkleProofVerificationError();
    error OnlyMerkleRootSetterError();
    error OnlyFundsClaimerError();
    error ConstructorParamError(string param);

    using Math for uint256;

    bytes32 public constant MERKLE_ROOT_SETTER_ROLE = keccak256("MERKLE_ROOT_SETTER_ROLE");
    bytes32 public constant FUNDS_CLAIMER_ROLE = keccak256("FUNDS_CLAIMER_ROLE");

    uint256 public immutable startTime;
    uint256 public immutable endTime;

    IMeritMintableNFT public immutable NFT;

    uint256 public immutable saleCap;
    uint256 public immutable idOffset; // ID to start minting at

    uint256 public immutable capPerUser;
    uint256 public immutable price;

    uint256 public totalSold;
    mapping(address => uint256) public userBought;
    bytes32 public merkleRoot; //set to bytes32(type(uint256).max) to remove whitelist

    modifier onlyMerkleRootSetter {
        if(!hasRole(MERKLE_ROOT_SETTER_ROLE, msg.sender)) {
            revert OnlyMerkleRootSetterError();
        }
        _;
    }

    modifier onlyFundsClaimer {
        if(!hasRole(FUNDS_CLAIMER_ROLE, msg.sender)) {
            revert OnlyFundsClaimerError();
        }
        _;
    }


    /// @notice constructor
    /// @param _merkleRoot merkle root
    /// @param _startTime start time of the sale
    /// @param _endTime end time of the sale
    /// @param _NFT address of the nft contract
    /// @param _saleCap maximum of nfts sold during the sale
    /// @param _capPerUser maximum a single address can buy
    /// @param _price price per nft
    /// @param _idOffset offset from which to start the incrementing of token ids
    constructor(
        bytes32 _merkleRoot,
        uint256 _startTime,
        uint256 _endTime,
        address _NFT,
        uint256 _saleCap,
        uint256 _capPerUser,
        uint256 _price,
        uint256 _idOffset
        
    ) {
        if(_startTime > _endTime) {
            revert ConstructorParamError("_startTime > _endTime");
        }
        if(_endTime < block.timestamp) {
            revert ConstructorParamError("_endTime < block.timestamp");
        }
        if(_NFT == address(0)) {
            revert ConstructorParamError("_NFT == address(0)");
        }
        if(_saleCap == 0) {
            revert ConstructorParamError("_saleCap == 0");
        }
        if(_capPerUser == 0) {
            revert ConstructorParamError("_capPerUser == 0");
        }

        merkleRoot = _merkleRoot;
        startTime = _startTime;
        endTime = _endTime;
        NFT = IMeritMintableNFT(_NFT);
        saleCap = _saleCap;
        capPerUser = _capPerUser;
        price = _price;
        idOffset = _idOffset;

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /// @notice Set the merkle root. Can only be called by a merkle root setter
    /// @param _merkleRoot new merkleRoot
    function setMerkleRoot(bytes32 _merkleRoot) external onlyMerkleRootSetter {
        merkleRoot = _merkleRoot;
    }

    /// @notice Claim funds received from the sale
    /// @param _receiver address receiving the funds
    function claimFunds(address _receiver) external onlyFundsClaimer() {
        payable(_receiver).transfer(address(this).balance);
    }

    /// @notice Buy an NFT
    /// @param _amount amount of nfts to buy
    /// @param _receiver address receiving the bought nfts
    /// @param _proof merkle proof confirming inclusion in the whitelist
    function buy(uint256 _amount, address _receiver, uint256 _size, bytes32[] calldata _proof) external payable {
        if(startTime > block.timestamp) {
            revert SaleNotStartedError();
        }
        if(endTime < block.timestamp) {
            revert SaleEndedError();
        }

        // mint max what's left or max mint per user
        uint256 amount = _amount.min(saleCap - totalSold).min(capPerUser - userBought[msg.sender]);

        if(amount == 0) {
            revert ZeroMintError();
        }
        
        // TODO custom errors
        uint256 totalEthRequired = amount * price;

        if(totalEthRequired > msg.value) {
            revert InsufficientETHError();
        }
 
        // If merkle root is 0xfffff...ffffff whitelist check is skipped
        if(merkleRoot != bytes32(type(uint256).max)) {
            bytes32 leaf = keccak256(abi.encodePacked(msg.sender)); // we only check if an address is in the merkle tree;
            if(!MerkleProof.verify(_proof, merkleRoot, leaf)) {
                revert MerkleProofVerificationError();
            }
        }        

        // reading totalSold once to save on storage writes
        uint256 nextId = totalSold + idOffset;
        // Updating totalSold before doing possible external calls
        totalSold += amount;
        userBought[msg.sender] += amount;

        // External calls at the end of the function
        // mint NFTS
        for(uint256 i = 0; i < amount; i ++) {
            NFT.mint(nextId, _receiver, _size);
            nextId ++;
        }

        // return excess ETH
        if(msg.value > totalEthRequired) {
            payable(msg.sender).transfer(msg.value - totalEthRequired);
        }
    }

}