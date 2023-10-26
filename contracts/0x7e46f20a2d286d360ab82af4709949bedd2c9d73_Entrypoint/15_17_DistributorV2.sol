// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

/*
The DistributorV2 is a clone contract version of the Uniswap Distributor. 
It expects a merkleRoot and a manifest, which is a public IPFS CID where to find
the full merkle tree.
*/

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "../initializable/Initializable.sol";
import "../interfaces/IDistributorV2.sol";

contract DistributorV2 is Initializable, IDistributorV2 {
    address public override token;
    bytes32 public override merkleRoot;
    string public manifest;
    // This is a packed array of booleans.
    mapping(uint256 => uint256) private claimedBitMap;
    // The returnTokenAddress is here for safety purposes. Its intended use is 
    // only when something goes wrong with the distributor and we need to redo
    // it. If this has a primary funder (like with the Amaranth Prize), then it
    // is set to that funder. Otherwise, it is set to the gnosis address for the
    // RP org. This is sacrificing some web3 purity for the sake of user
    // experience, where user is both funder and recipient.
    address public returnTokenAddress;

    // The researchPortfolioGnosis should be one of the following:
    // Goerli: 0x6f07856f4974A32a54A0A0045eDfAEd97Cc78136
    // Mainnet: 0xAAbF8DC8c8208e023c5D8e2d0e3dd30415559E0E
    address public researchPortfolioGnosis;

    error InvalidSenderAddress();
    error MerkleRootIsZero();
    error ManifestIsEmpty();
    error NullReturnTokenAddress();
    error TokenIsSet();
    error TokenIsZeroAddress();
    error AlreadyClaimed();
    error InvalidProof();
    error TransferFailed();
    
    function initialize(
        bytes32 merkleRoot_,
        string memory manifest_,
        address returnTokenAddress_,
        address researchPortfolioGnosis_
    ) public virtual initializer {
        if (merkleRoot_ == bytes32(0)) {
            revert MerkleRootIsZero();
        }
        if (bytes(manifest_).length == 0) {
            revert ManifestIsEmpty();
        }        
        __DistributorV2_init(merkleRoot_, manifest_, returnTokenAddress_, 
            researchPortfolioGnosis_);
    }

    function __DistributorV2_init(
        bytes32 merkleRoot_,
        string memory manifest_,
        address returnTokenAddress_,
        address researchPortfolioGnosis_
    ) internal initializer {
        // Do the chain of initializations here.
        __DistributorV2_init_unchained(merkleRoot_, manifest_, 
            returnTokenAddress_, researchPortfolioGnosis_);
    }

    function __DistributorV2_init_unchained(
        bytes32 merkleRoot_,
        string memory manifest_,
        address returnTokenAddress_,
        address researchPortfolioGnosis_
    ) internal initializer {
        merkleRoot = merkleRoot_;
        manifest = manifest_;
        returnTokenAddress = returnTokenAddress_;
        researchPortfolioGnosis = researchPortfolioGnosis_;
    }

    function setToken(address token_) external override {
        if (token != address(0x0)) {
            revert TokenIsSet();
        }
        if (token_ == address(0x0)) {
            revert TokenIsZeroAddress();
        }
        token = token_;
        emit ERC20Distribution(token_, DistributorTypeMerkleV2);
    }

    function isClaimed(uint256 index) public view override returns (bool) {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        uint256 claimedWord = claimedBitMap[claimedWordIndex];
        uint256 mask = (1 << claimedBitIndex);
        return claimedWord & mask == mask;
    }

    function _setClaimed(uint256 index) private {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        claimedBitMap[claimedWordIndex] =
            claimedBitMap[claimedWordIndex] |
            (1 << claimedBitIndex);
    }

    function claimForAccount(
        uint256 index,
        uint256 amount,
        address account,
        bytes32[] calldata merkleProof
    ) public override {
        if (isClaimed(index)) {
            revert AlreadyClaimed();
        }

        // Verify the merkle proof.
        bytes32 node = keccak256(
            abi.encodePacked(index, amount, account)
        );
        if (!MerkleProof.verify(merkleProof, merkleRoot, node)) {
            revert InvalidProof();
        }

        // Mark it claimed and send the token.
        _setClaimed(index);
        if (!IERC20(token).transfer(account, amount)) {
            revert TransferFailed();
        }
        emit ERC20ClaimForAccount(index, amount, account);
    }

    /*
    Withdraw can only be called by a Research Portfolio gnosis address, which
    are hardcoded at the top. This is in order to limit the action just to the 
    trusted organization. Note that if the returnTokenAddress is not set, then
    this function doesn't actually do anything. Otherwise, the withdrawn token 
    goes to the returnTokenAddress. 
    
    This is just meant to be used in case of there being a problem with this 
    distributor.
    */
    function withdraw() external {
        if (returnTokenAddress == address(0x0)) {
            revert NullReturnTokenAddress();
        }
        if (msg.sender != researchPortfolioGnosis) {
            revert InvalidSenderAddress();
        }        

        uint256 balance = IERC20(token).balanceOf(address(this));
        if (!IERC20(token).transfer(returnTokenAddress, balance)) {
            revert TransferFailed();
        }
    }

    /*
    withdrawBalance is similar to above. The difference is that the caller can 
    specify an amount to transfer.
    
    This is just meant to be used in case of there being a problem with this 
    distributor and we want to return a small amount. An example is if the email
    embedded wallet is unreachable.
    */
    function withdrawAmount(uint256 amount) external {
        if (returnTokenAddress == address(0x0)) {
            revert NullReturnTokenAddress();
        }
        if (msg.sender != researchPortfolioGnosis) {
            revert InvalidSenderAddress();
        }        
        
        if (!IERC20(token).transfer(returnTokenAddress, amount)) {
            revert TransferFailed();
        }
    }    
}