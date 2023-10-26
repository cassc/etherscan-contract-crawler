// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../util/MerkleVerify.sol";
import "../util/Strings.sol";
import "./Itoken.sol";
import "./FailSafeFees.sol";
import "./SigUtil.sol";
import "./FailSafeBeacon.sol";
import "./FailSafeByteCodeConstants.sol";

/**
 * @dev FailSafeOrchestrator responsible for spining up new FailSafeWallets 
 * (on first asset defences) as well as calling the dedicated existing
 * wallets for fund protection.  Uses FailSafeFees to compensate for the gas
 * spent.
 * 
 */
contract FailSafeOrchestrator is StringsF, MerkleVerify, Fees, SigUtil, OwnableUpgradeable {
    bytes32 public interceptRoot;
    // Act like an expiration date.  Used to protect 
    // freshness of delegated signed transactions
    uint public blockSkewDelta;

    // number of falesawallets created
    uint public failSafeWalletCount;
    uint public defendCount;
    // only here for upgradability purposes
    uint public lastGasConsumed;

    FailSafeBeacon beacon;
    uint public defend1GasUnits;
    uint public defendNGasUnits;
    // do not remove, need to preserve the state 
    // of the proxy
    address public contractConstantAddr;

    // NOTE: puting re-entrency code directly 
    // here so state of the proxy is not effected.
    uint256 private constant _NOT_ENTERED = 0;
    uint256 private constant _ENTERED = 1;

    uint256 private _status;

     modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        _status = _NOT_ENTERED;
    }

    function initialize(address failSafeWalletBlueprint) external initializer {
        beacon = new FailSafeBeacon(failSafeWalletBlueprint);
        __Ownable_init();
        transferOwnership(tx.origin);
    }

    event DefendFailSafeERC20(address protectedAddr, address tok);
    event DefendFailSafeERC721(address protectedAddr, address tok);

    function setConfSettings(
        address _gasToken,
        uint _blockSkewDelta,
        uint _defend1GasUnits,
        uint _defendNGasUnits,
        address _contractConstantAddr
       
    ) external onlyOwner {
        initFees(_gasToken);

        require(_gasToken != address(0), "invalid gas token addr");
        require(_contractConstantAddr != address(0), "invalid const addr");
        require(_blockSkewDelta >0, "no blockSkewDelta specified");

        blockSkewDelta = _blockSkewDelta;
        defend1GasUnits = _defend1GasUnits;
        defendNGasUnits = _defendNGasUnits;
        contractConstantAddr =_contractConstantAddr;
    }

    function setRoot(bytes32 root) external onlyOwner {
        interceptRoot = root;
    }

    function getRoot() external view returns (bytes32) {
        return interceptRoot;
    }

    function authzCheck(
        bytes32 root,
        address caller,
        bytes32[] memory proof
    ) public pure returns (bool authorized) {
        require(root != bytes32(0x0), "Root not initialized");
        string memory leafSource = toUpper(addressToString(caller));

        // Checks that the address is present in the merkele tree
        return verify(proof, root, leafSource);
    }

    // defends erc20 tokens
    function jitFailSafe(
        uint version,
        // protected token
        address erc20Addr, 
        address protectedAddr,
        address feeCompAuthorizer,
        bytes32 fsRoot,
        // merkle proof for authz check
        bytes32[] memory proof 
    ) external payable nonReentrant {
        require(fsRoot != bytes32(0x0), "intercept fsRoot not initialized");
        require(
            authzCheck(interceptRoot, msg.sender, proof),
            "not authorized to call jitFailSafe2"
        );
        bytes32 _salt = getSalt(protectedAddr, version);

        address predictedAddress = getAddress(_salt, protectedAddr);

        Erc20 underlying = Erc20(erc20Addr);
        uint256 allowance = underlying.allowance(protectedAddr, predictedAddress);
        require(allowance > 0, "insufficient allowance!");

        uint256 protectedAddrBal = underlying.balanceOf(protectedAddr);
        require(protectedAddrBal > 0, "no funds to protect!");

        FailSafeWallet _contract;

        uint gasBill = 0;
        // only create it if its the first time
        if (predictedAddress.code.length > 0) {
            gasBill = defendNGasUnits * tx.gasprice;
            _contract = FailSafeWallet(predictedAddress);
        } else {
            gasBill = defend1GasUnits * tx.gasprice;
            BeaconProxy _proxyContract = new BeaconProxy{salt: _salt}(
                address(beacon),
                abi.encodeWithSelector(
                    FailSafeWallet(address(0)).initialize.selector,
                    address(this),
                    protectedAddr
                )
            );

            failSafeWalletCount++;
            address proxyContractAddress = address(_proxyContract);

            require(proxyContractAddress == predictedAddress, "predicted address does not match");
            _contract = FailSafeWallet(predictedAddress);
            // Only set merkle root on new deployment
            _contract.setRoot(fsRoot);
        }

        if (erc20Addr == gasToken) {
            _contract.defend(erc20Addr, gasBill);
        } else {
            _contract.defend(erc20Addr, 0);
        }

        defendCount++;

        comp (gasBill, feeCompAuthorizer, version);

        emit DefendFailSafeERC20(protectedAddr, erc20Addr);
    }

    // defends erc721 tokens
    function jitFailSafe721(
        uint version,
        address erc721Addr,
        uint tokenId,
        address protectedAddr,
        address feeCompAuthorizer,
        bytes32 fsRoot,
        bytes32[] memory proof 
    ) external payable {
        uint[] memory tokenIds = new uint[](1);
        tokenIds[0] = tokenId;

         jitFailSafe721Batch(
                version,
                erc721Addr, 
                tokenIds,
                protectedAddr,
                feeCompAuthorizer,
                fsRoot,
                proof 
            );
    }

    function jitFailSafe721Batch(
        uint version,
        // token to defend
        address erc721Addr, 
        uint[] memory tokenIds,
        address protectedAddr,
        address feeCompAuthorizer,
        bytes32 fsRoot,
        // to support authz check
        bytes32[] memory proof 
    ) public payable nonReentrant {
        require(fsRoot != bytes32(0x0), "intercept fsRoot not initialized");
        require(
            authzCheck(interceptRoot, msg.sender, proof),
            "not authorized to call jitFailSafe2"
        );
        
        require(erc721Addr != address(0), "invalid erc721Addr");
        require(protectedAddr != address(0), "invalid protected addr");
        require(feeCompAuthorizer != address(0), "invalid fee comp addr");
        require(tokenIds.length >0, "no tokein ids found");

        bytes32 _salt = getSalt(protectedAddr, version);
        address predictedAddress = getAddress(_salt, protectedAddr);
        Erc721 underlying = Erc721(erc721Addr);
  
        FailSafeWallet _contract;
        uint gasBill = 0;
        // only create it if its the first time
        if (predictedAddress.code.length > 0) {
            gasBill = defendNGasUnits * tx.gasprice;
            _contract = FailSafeWallet(predictedAddress);
        } else {
            gasBill = defend1GasUnits * tx.gasprice;
            BeaconProxy _proxyContract = new BeaconProxy{salt: _salt}(
                address(beacon),
                abi.encodeWithSelector(
                    FailSafeWallet(address(0)).initialize.selector,
                    address(this),
                    protectedAddr
                )
            );
            failSafeWalletCount++;
            address proxyContractAddress = address(_proxyContract);
            require(proxyContractAddress == predictedAddress, "predicted address does not match");
            _contract = FailSafeWallet(predictedAddress);
            // Only set merkle root on new deployment
            _contract.setRoot(fsRoot);
        }

         bool opAllowed = underlying.isApprovedForAll(protectedAddr, predictedAddress);

         for (uint i = 0; i < tokenIds.length; i++) {

            if (!opAllowed){
                 require(predictedAddress == underlying.getApproved(tokenIds[i]), "fs wallet no perms for token id!");
            }

            require(protectedAddr == underlying.ownerOf(tokenIds[i]), "protected addr not owner of token id!");
            
           lastGasConsumed = gasleft();
           _contract.defend721(erc721Addr, tokenIds[i]);
           lastGasConsumed -= gasleft();

            defendCount++;
        }

        gasBill += (tokenIds.length -1) * lastGasConsumed * tx.gasprice;
        comp (gasBill, feeCompAuthorizer, version);

        emit DefendFailSafeERC721(protectedAddr, erc721Addr);
    }

    function comp(uint gasBill, address feeCompAuthorizer, uint version) internal {
        payFees(gasBill, feeCompAuthorizer, getFailsafeContractAddress(feeCompAuthorizer, version));
    }

    function getFailsafeContractAddress(
        address protectedAddr,
        uint version
    ) public view returns (address) {
        return getAddress(getSalt(protectedAddr, version), protectedAddr);
    }

    function getBeacon() public view returns (address) {
        return address(beacon);
    }

    function getImplementation() public view returns (address) {
        return beacon.implementation();
    }

    function getSalt(address protectedAddr, uint version) internal view returns (bytes32) {
        bytes32 _salt = keccak256(
            abi.encodePacked(
                bytes1(0xff),
                protectedAddr,
                version,
                keccak256(getBytecode(address(this), protectedAddr))
            )
        );
        return _salt;
    }

    function getAddress(bytes32 _salt, address protectedAddr) internal view returns (address) {
        bytes memory bytecode = getBytecode1(
            address(beacon),
            abi.encodeWithSelector(
                FailSafeWallet(address(0)).initialize.selector,
                address(this),
                protectedAddr
            )
        );

        bytes32 hash = keccak256(
            abi.encodePacked(bytes1(0xff), address(this), _salt, keccak256(bytecode))
        );
        return address(uint160(uint(hash)));
    }

    function getBytecode(
        address _owner,
        address protectedAddr
    ) internal pure returns (bytes memory) {
        bytes memory bytecode = type(BeaconProxy).creationCode;
        return abi.encodePacked(bytecode, abi.encode(_owner, protectedAddr));
    }

    function getBytecode1(
        address beaconAddr,
        bytes memory _stream
    ) internal pure returns (bytes memory) {
        bytes memory bytecode = type(BeaconProxy).creationCode;
        return abi.encodePacked(bytecode, abi.encode(beaconAddr, _stream));
    }

    receive() external payable {}
}