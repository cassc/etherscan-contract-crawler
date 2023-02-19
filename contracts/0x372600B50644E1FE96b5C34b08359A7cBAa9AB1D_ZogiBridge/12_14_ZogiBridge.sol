// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "../accessControl/AccessProtectedUpgradable.sol";
import "../utils/Percentage.sol";
import "../interfaces/IZogi.sol";

contract ZogiBridge is PausableUpgradeable,ReentrancyGuardUpgradeable,
    AccessProtectedUpgradable,Percentage
    {
    using ECDSAUpgradeable for bytes32;

    bytes32 public ssHash;
    bool private initialized;
    uint256 public bridgeFeePercentage;

    IZOGI public zogiToken;

    mapping(bytes32 => bool) public records;
    mapping(uint256 => bool) public supportedChains;
    
    event BridgeBurn(address indexed owner, uint256 amount, uint256 indexed originChainId, uint256 indexed toChainId, bytes32 burnId);
    event BridgeMint(address indexed owner, uint256 amount, uint256 indexed originChainId, uint256 indexed toChainId, bytes32 refId, bytes32 mintId);
    event SignersUpdated(address[] signers);
    event BridgeFeeUpdate(uint256 feePercentage);

    function init(address zogiAddr, uint256 bridgeFee_, uint256 percentageDecimals_, uint256[]memory chainIds_, 
        bool[]memory chainStatus_) external initializer
    {
        require(!initialized, "Can not re-initialize");
        require(bridgeFeePercentage < 1000, "Can not charge 100% fee");
        initialized = true;

        zogiToken = IZOGI(zogiAddr);
        bridgeFeePercentage = bridgeFee_;
        _updateSupportedChains(chainIds_, chainStatus_);

        __Ownable_init();
        __Context_init();
        __Pausable_init();
        __ReentrancyGuard_init();
        __Percentage_init(percentageDecimals_);

    }

    // =========== external functions =============
    
    function bridgeBurn(uint256 amount_, uint256 toChainId_, uint256 nonce_) external whenNotPaused nonReentrant returns(bytes32 burnId){
        require(zogiToken.balanceOf(msg.sender) >= amount_, "Not enough balance");
        require(supportedChains[toChainId_], "Invalid chain id");

        uint256 bridgeFeePercentage_ = (calculatePercentage(bridgeFeePercentage, 100)/10);
        uint256 bridgeFee_ = calculateValueOfPercentage(bridgeFeePercentage_, amount_);
        uint256 bridgeAmount_ = amount_ - bridgeFee_;
        
        burnId = keccak256(
            abi.encodePacked(
                msg.sender,
                bridgeAmount_,
                toChainId_,
                nonce_,
                uint256(block.chainid),
                address(this)
            )
        );

        require(records[burnId] == false, "record already exists");
        records[burnId] = true;
        
        zogiToken.transferFrom(msg.sender, address(this), amount_);
        zogiToken.burn(bridgeAmount_);

        emit BridgeBurn(msg.sender, bridgeAmount_, uint256(block.chainid), toChainId_, burnId);
    }

    function bridgeMint(bytes32 refId_,uint256 amount_, uint256 originChainId_,bytes[] memory signature_, address[] calldata signers_)
        external whenNotPaused nonReentrant returns(bytes32 mintId){

        bytes32 h = keccak256(abi.encodePacked(signers_));
        require(ssHash == h, "Mismatch current signers");

        mintId = keccak256(
            abi.encodePacked(
                originChainId_,
                uint256(block.chainid), // current chain id
                address(this),
                refId_,
                msg.sender,
                amount_
                )
            );

        bytes32 prefixedHash = mintId.toEthSignedMessageHash();

        address prev = address(0);
        for(uint256 i =0; i< signers_.length; i++){
            address msgSigner = recover(prefixedHash, signature_[i]);
            require(msgSigner > prev, "signers not in ascending order");
            prev = msgSigner;
            require(msgSigner == signers_[i], "Invalid signature");
        }

        require(records[mintId] == false, "record exists");
        records[mintId] = true;

        zogiToken.mint(msg.sender, amount_);
        emit BridgeMint(msg.sender, amount_, originChainId_, uint64(block.chainid), refId_, mintId);
    }

    // =========== Owner only functions =============

    function updateSigners(address[] calldata _signers) external onlyOwner{
        require(_signers.length >=1, "Signer list should be greater than zero");
        _updateSigners(_signers);
    }

    function withDrawFee() external onlyOwner{
        zogiToken.transfer(owner(), zogiToken.balanceOf(address(this)));
    }

    function updateFee(uint256 feePercentage_) external onlyOwner{
        require(feePercentage_ < 1000, "Can not charge 100% fee");
        bridgeFeePercentage = feePercentage_;
        emit BridgeFeeUpdate(feePercentage_);
    }

    function updatePercentageDecimals(uint256 newPercentageDecimals_) external onlyOwner{
        _updatePercentageDecimals(newPercentageDecimals_);
    }

    function updateSupportedChains(uint256[]memory chainIds_,bool[]memory chainStatus_) external onlyOwner{
        _updateSupportedChains(chainIds_, chainStatus_);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }
    
    function renounceOwnership() public view override onlyOwner {
        revert("can't renounceOwnership here");
    }
    
    // =========== private helper functions =============

    function _updateSupportedChains(uint256[]memory chainIds_, bool[]memory status_) private{
        require(chainIds_.length == status_.length, "Array length mismatch");

       for (uint256 i = 0; i < chainIds_.length; i++) {
           supportedChains[chainIds_[i]] = status_[i];
        }
    }

    function recover(bytes32 hash, bytes memory signature_) private pure returns(address) {
        return hash.recover(signature_);
    }

    function _updateSigners(address[] calldata _signers) private {
        address prev = address(0);
        for (uint256 i = 0; i < _signers.length; i++) {
            require(_signers[i] > prev, "New signers not in ascending order");
            prev = _signers[i];
        }
        ssHash = keccak256(abi.encodePacked(_signers));
        emit SignersUpdated(_signers);
    }

}