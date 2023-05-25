// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./interfaces/IHoneyToken.sol";
import "./interfaces/IFancyBears.sol";
import "./interfaces/IFancyBearStaking.sol";
import "./interfaces/IHive.sol";

contract FancyBearStakingRewardV2 is AccessControlEnumerable {
    
    using SafeERC20 for IHoneyToken;
 
    enum ClaimingStatus {
        Off,
        Active
    }

    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    bytes32 public walletsMerkleRoot;
    bytes32 public tokenToHiveMerkleRoot;

    IHoneyToken public honeyContract;
    IFancyBears public fancyBearsContract;
    IFancyBearStaking public fancyBearStakingContract;
    IHive public hiveContract;

    ClaimingStatus public claimingStatus;
    uint256 public maxHoneyRewardAmount;

    mapping(address => uint256) public claimedHoneyForWallets;
    mapping(uint256 => uint256) public claimedHoneyForBearToHive;

    event ClaimedToWallet(address indexed _to, uint256 _honeyAmount);
    event ClaimedToHive(uint256 indexed _tokenId, uint256 _honeyAmount);

constructor(
        IHoneyToken _honeyContractAddress, 
        IFancyBears _fancyBearsContractAddress, 
        IFancyBearStaking _fancyBearStakingContract, 
        IHive _hiveContract
    ) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MANAGER_ROLE, msg.sender);
        honeyContract = _honeyContractAddress;
        fancyBearsContract = _fancyBearsContractAddress;
        fancyBearStakingContract = _fancyBearStakingContract;
        hiveContract = _hiveContract;
        claimingStatus = ClaimingStatus.Off;
        maxHoneyRewardAmount = 2000000 ether;
    }

    function setClaimingStatus(ClaimingStatus _claimingStatus)
        public
        onlyRole(MANAGER_ROLE)
    {
        claimingStatus = _claimingStatus;
    }

    function setMaxHoneyRewardAmount(uint256 _amount) public onlyRole(MANAGER_ROLE) {
        maxHoneyRewardAmount = _amount;
    }

    // merkle tree  -----------------------------

    function setWalletsMerkleRoot(bytes32 _newWalletsMerkleRoot) external onlyRole(MANAGER_ROLE) {
        require(claimingStatus == ClaimingStatus.Off, "setWalletsMerkleRoot: claiming must be off!");
        walletsMerkleRoot = _newWalletsMerkleRoot;
    }

    function getLeafForWallet(address _address, uint256 _amount) public pure returns (bytes32) {
        return keccak256(bytes.concat(keccak256(abi.encode(_address, _amount))));
    }

    function setTokenToHiveMerkleRoot(bytes32 _newTokenToHiveMerkleRoot) external onlyRole(MANAGER_ROLE) {
        require(claimingStatus == ClaimingStatus.Off, "setTokenToHiveMerkleRoot: claiming must be off!");
        tokenToHiveMerkleRoot = _newTokenToHiveMerkleRoot;
    }

    function getLeafForTokenToHive(uint256 _tokenId, uint256 _amount) public pure returns (bytes32) {
        return keccak256(bytes.concat(keccak256(abi.encode(_tokenId, _amount))));
    }

    // wallet -----------------------------

    function claimHoneyRewardToWallet(bytes32[] calldata _proof, uint256 _totalAmount) external {

        require(claimingStatus == ClaimingStatus.Active, "claimHoneyRewardToWallet: claiming is off!");
        require(walletsMerkleRoot != "", "claimHoneyRewardToWallet: merkle tree not set!");

        require(
            MerkleProof.verify(
                _proof,
                walletsMerkleRoot,
                getLeafForWallet(msg.sender, _totalAmount)
            ),
            "claimHoneyRewardToWallet: whitelisting validation failed"
        );
        
        uint256 amountToTransfer = _totalAmount - claimedHoneyForWallets[msg.sender];

        require(amountToTransfer > 0, "claimHoneyRewardToWallet: everything what was available is already claimed!");

        emit ClaimedToWallet(msg.sender, amountToTransfer);  
        claimedHoneyForWallets[msg.sender] += amountToTransfer;
        
        honeyContract.safeTransfer(msg.sender, amountToTransfer);

    }

    // hive -----------------------------

    function claimHoneyRewardToHive(bytes32[][] calldata _proofs, uint256[] calldata _tokenIds, uint256[] calldata _totalAmounts) external {

        require(claimingStatus == ClaimingStatus.Active, "claimHoneyRewardToHive: claiming is off!");
        require(tokenToHiveMerkleRoot != "", "claimHoneyRewardToHive: merkle tree not set!");
        
        uint256 loopLength = _tokenIds.length;

        require(
            _proofs.length == loopLength && _totalAmounts.length == loopLength,
            "claimHoneyRewardToHive: the length of the input arrays must be the same."
        );

        address[] memory collections = new address[](loopLength);
        uint256[] memory amountsToTransfer = new uint256[](loopLength);
        uint256 totalHoneyAmounts;

        for (uint256 i; i < loopLength; i++) {

            require(
                MerkleProof.verify(
                    _proofs[i],
                    tokenToHiveMerkleRoot,
                    getLeafForTokenToHive(_tokenIds[i], _totalAmounts[i])
                ),
                "claimHoneyRewardToHive: whitelisting validation failed"
            );
         
            uint256 amountToTransfer = _totalAmounts[i] - claimedHoneyForBearToHive[_tokenIds[i]];

            require(amountToTransfer > 0, "claimHoneyRewardToWallet: everything what was available is already claimed!");

            require(
                fancyBearsContract.ownerOf(_tokenIds[i]) == msg.sender || fancyBearStakingContract.getOwnerOf(_tokenIds[i]) == msg.sender,
                "claimHoneyRewardToHive: FancyBear, the sender is not the owner of the token and the token is not staked too."
            );
         
            collections[i] = address(fancyBearsContract);
            amountsToTransfer[i] = amountToTransfer;
            totalHoneyAmounts += amountToTransfer;

            emit ClaimedToHive(_tokenIds[i], amountToTransfer);

            claimedHoneyForBearToHive[_tokenIds[i]] += amountToTransfer;

        }
            
        honeyContract.approve(address(hiveContract), totalHoneyAmounts);
        hiveContract.depositHoneyToTokenIdsOfCollections(collections, _tokenIds, amountsToTransfer);

    }

    function getClaimedHoneyForWallets(address[] calldata wallets) public view returns (uint256[] memory) {
        
        uint256 inputLength = wallets.length;
        uint256[] memory claimedData = new uint256[](inputLength);
        
        for(uint256 i; i < inputLength; i++) {
            claimedData[i] = claimedHoneyForWallets[wallets[i]];
        }

        return claimedData;
    }

    function getClaimedHoneyForBearsToHive(uint256[] calldata tokenIds) public view returns (uint256[] memory) {

        uint256 inputLength = tokenIds.length;
        uint256[] memory claimedData = new uint256[](inputLength);
        
        for(uint256 i; i < inputLength; i++) {
            claimedData[i] = claimedHoneyForBearToHive[tokenIds[i]];
        }

        return claimedData;
    }

}