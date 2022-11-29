// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165CheckerUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "./drop/lib/CurrencyTransferLib.sol";
import "./drop/CedarERC721DropFactory.sol";
import "./drop/CedarERC1155DropFactory.sol";
import "./paymentSplit/CedarPaymentSplitterFactory.sol";
import "./generated/deploy/BaseCedarDeployerV10.sol";
import "./drop/CedarERC1155DropDelegateLogicFactory.sol";
import "./drop/CedarERC721DropDelegateLogicFactory.sol";

contract CedarDeployer is Initializable, UUPSUpgradeable, AccessControlUpgradeable, BaseCedarDeployerV10 {
    CedarERC721DropFactory drop721Factory;
    CedarERC1155DropFactory drop1155Factory;
    CedarPaymentSplitterFactory paymentSplitterFactory;
    CedarERC1155DropDelegateLogicFactory drop1155DelegateLogicFactory;
    CedarERC721DropDelegateLogicFactory drop721DelegateLogicFactory;

    using ERC165CheckerUpgradeable for address;

    uint256 public deploymentFee;
    address payable public feeReceiver;

    error IllegalVersionUpgrade(
        uint256 existingMajorVersion,
        uint256 existingMinorVersion,
        uint256 existingPatchVersion,
        uint256 newMajorVersion,
        uint256 newMinorVersion,
        uint256 newPatchVersion
    );

    error ImplementationNotVersioned(address implementation);
    error DeploymentFeeAlreadySet(uint256 existingFee);
    error FeeReceiverAlreadySet(address existingReceiver);

    function initialize(
        CedarERC721DropFactory _drop721Factory,
        CedarERC1155DropFactory _drop1155Factory,
        CedarPaymentSplitterFactory _paymentSplitterFactory,
        CedarERC1155DropDelegateLogicFactory _drop1155DelegateLogicFactory,
        CedarERC721DropDelegateLogicFactory _drop721DelegateLogicFactory,
        uint256 _deploymentFee,
        address _feeReceiver
    ) public virtual initializer {
        drop721Factory = _drop721Factory;
        drop1155Factory = _drop1155Factory;
        paymentSplitterFactory = _paymentSplitterFactory;
        drop1155DelegateLogicFactory = _drop1155DelegateLogicFactory;
        drop721DelegateLogicFactory = _drop721DelegateLogicFactory;
        deploymentFee = _deploymentFee;
        feeReceiver = payable(_feeReceiver);

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /// @dev See ERC 165
    /// NOTE: Due to this function being overridden by 2 different contracts, we need to explicitly specify the interface here
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(BaseCedarDeployerV10, AccessControlUpgradeable)
        returns (bool)
    {
        return
            BaseCedarDeployerV10.supportsInterface(interfaceId) ||
            AccessControlUpgradeable.supportsInterface(interfaceId);
    }

    /// ================================
    /// ========== Owner Only ==========
    /// ================================
    function reinitialize(
        CedarERC721DropFactory _drop721Factory,
        CedarERC1155DropFactory _drop1155Factory,
        CedarPaymentSplitterFactory _paymentSplitterFactory,
        CedarERC1155DropDelegateLogicFactory _drop1155DelegateLogicFactory,
        CedarERC721DropDelegateLogicFactory _drop721DelegateLogicFactory
    ) public virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        drop721Factory = _drop721Factory;
        drop1155Factory = _drop1155Factory;
        paymentSplitterFactory = _paymentSplitterFactory;
        drop1155DelegateLogicFactory = _drop1155DelegateLogicFactory;
        drop721DelegateLogicFactory = _drop721DelegateLogicFactory;
    }

    function _authorizeUpgrade(address newImplementation) internal view override onlyRole(DEFAULT_ADMIN_ROLE) {
        (uint256 major, uint256 minor, uint256 patch) = this.implementationVersion();
        if (!newImplementation.supportsInterface(type(ICedarVersionedV1).interfaceId)) {
            revert ImplementationNotVersioned(newImplementation);
        }
        (uint256 newMajor, uint256 newMinor, uint256 newPatch) = ICedarVersionedV1(newImplementation)
            .implementationVersion();
        // Do not permit a breaking change via an UUPS proxy upgrade - this requires a new proxy. Otherwise, only allow
        // minor/patch versions to increase
        if (major != newMajor || minor > newMinor || (minor == newMinor && patch > newPatch)) {
            revert IllegalVersionUpgrade(major, minor, patch, newMajor, newMinor, newPatch);
        }
    }

    /// @dev This functions updates the deployment fee and fee receiver address.
    /// @param _newDeploymentFee The new deployment fee
    /// @param _newFeeReceiver The new fee receiver address
    function updateDeploymentFeeDetails(uint256 _newDeploymentFee, address _newFeeReceiver)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        updateFeeReceiver(_newFeeReceiver);
        updateDeploymentFee(_newDeploymentFee);
    }

    // @dev This functions updates the deployment fee. The new fee must be different from the existing [email protected]
    /// @param _newDeploymentFee The new deployment fee
    function updateDeploymentFee(uint256 _newDeploymentFee) public onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_newDeploymentFee == deploymentFee) revert DeploymentFeeAlreadySet(deploymentFee);
        deploymentFee = _newDeploymentFee;
    }

    /// @dev This functions updates the fee receiver address. The new fee receiver address must be different from the existing one.
    /// @param _newFeeReceiver The new fee receiver address
    function updateFeeReceiver(address _newFeeReceiver) public onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_newFeeReceiver == feeReceiver) revert FeeReceiverAlreadySet(feeReceiver);
        feeReceiver = payable(_newFeeReceiver);
    }

    /// @dev This function disables the deployment fee by setting the fee value to 0.
    function disableDeploymentFee() public onlyRole(DEFAULT_ADMIN_ROLE) {
        deploymentFee = 0;
    }

    /// ================================
    /// ========== Deployments =========
    /// ================================
    function deployCedarERC721DropV5(
        address _defaultAdmin,
        string memory _name,
        string memory _symbol,
        string memory _contractURI,
        address[] memory _trustedForwarders,
        address _saleRecipient,
        address _royaltyRecipient,
        uint128 _royaltyBps,
        string memory _userAgreement,
        uint128 _platformFeeBps,
        address _platformFeeRecipient
    ) external payable override returns (ICedarERC721DropV7) {
        CedarERC721DropDelegateLogic drop721DelegateLogic = _deployDrop721DelegateLogic();
        CedarERC721Drop newContract = drop721Factory.deploy(
            _defaultAdmin,
            _name,
            _symbol,
            _contractURI,
            _trustedForwarders,
            _saleRecipient,
            _royaltyRecipient,
            _royaltyBps,
            _userAgreement,
            _platformFeeBps,
            _platformFeeRecipient,
            address(drop721DelegateLogic)
        );

        (uint256 major, uint256 minor, uint256 patch) = newContract.implementationVersion();
        string memory interfaceId = newContract.implementationInterfaceId();
        _payDeploymentFee();
        emit CedarInterfaceDeployed(address(newContract), major, minor, patch, interfaceId);
        return ICedarERC721DropV7(address(newContract));
    }

    function deployCedarERC1155DropV4(
        address _defaultAdmin,
        string memory _name,
        string memory _symbol,
        string memory _contractURI,
        address[] memory _trustedForwarders,
        address _saleRecipient,
        address _royaltyRecipient,
        uint128 _royaltyBps,
        string memory _userAgreement,
        uint128 _platformFeeBps,
        address _platformFeeRecipient
    ) external payable override returns (ICedarERC1155DropV5) {
        CedarERC1155DropDelegateLogic drop1155DelegateLogic = _deployDrop1155DelegateLogic();
        CedarERC1155Drop newContract = drop1155Factory.deploy(
            _defaultAdmin,
            _name,
            _symbol,
            _contractURI,
            _trustedForwarders,
            _saleRecipient,
            _royaltyRecipient,
            _royaltyBps,
            _userAgreement,
            _platformFeeBps,
            _platformFeeRecipient,
            address(drop1155DelegateLogic)
        );

        (uint256 major, uint256 minor, uint256 patch) = newContract.implementationVersion();
        string memory interfaceId = newContract.implementationInterfaceId();
        _payDeploymentFee();
        emit CedarInterfaceDeployed(address(newContract), major, minor, patch, interfaceId);
        return ICedarERC1155DropV5(address(newContract));
    }

    function deployCedarPaymentSplitterV2(address[] memory payees, uint256[] memory shares_)
        external
        override
        returns (ICedarPaymentSplitterV2)
    {
        CedarPaymentSplitter newContract = paymentSplitterFactory.deploy(payees, shares_);
        string memory interfaceId = newContract.implementationInterfaceId();
        (uint256 major, uint256 minor, uint256 patch) = newContract.implementationVersion();
        emit CedarInterfaceDeployed(address(newContract), major, minor, patch, interfaceId);
        return ICedarPaymentSplitterV2(address(newContract));
    }

    /// ================================
    /// =========== Versioning =========
    /// ================================
    function cedarERC721DropVersion()
        external
        view
        override
        returns (
            uint256 major,
            uint256 minor,
            uint256 patch
        )
    {
        return drop721Factory.implementationVersion();
    }

    function cedarERC1155DropVersion()
        external
        view
        override
        returns (
            uint256 major,
            uint256 minor,
            uint256 patch
        )
    {
        return drop1155Factory.implementationVersion();
    }

    function cedarPaymentSplitterVersion()
        external
        view
        override
        returns (
            uint256 major,
            uint256 minor,
            uint256 patch
        )
    {
        return paymentSplitterFactory.implementationVersion();
    }

    /// ================================
    /// =========== Features ===========
    /// ================================
    function cedarERC721DropFeatures() public view override returns (string[] memory features) {
        return drop721Factory.implementation().supportedFeatures();
    }

    function cedarERC1155DropFeatures() public view override returns (string[] memory features) {
        return drop1155Factory.implementation().supportedFeatures();
    }

    function cedarPaymentSplitterFeatures() external view override returns (string[] memory features) {
        return paymentSplitterFactory.implementation().supportedFeatures();
    }

    /// ================================
    /// ======= Internal Methods =======
    /// ================================
    function _deployDrop721DelegateLogic() internal returns (CedarERC721DropDelegateLogic) {
        return drop721DelegateLogicFactory.deploy();
    }

    function _deployDrop1155DelegateLogic() internal returns (CedarERC1155DropDelegateLogic) {
        return drop1155DelegateLogicFactory.deploy();
    }

    /// @dev This function checks if both the deployment fee and fee receiver address are set.
    ///     If they are, then it pays the deployment fee to the fee receiver.
    function _payDeploymentFee() internal {
        if (deploymentFee > 0 && feeReceiver != address(0)) {
            CurrencyTransferLib.safeTransferNativeToken(feeReceiver, deploymentFee);
        }
    }

    /// ================================
    /// ======== Miscellaneous =========
    /// ================================
    // Concrete implementation semantic version - provided for completeness but not designed to be the point of dispatch
    function minorVersion() public pure virtual override returns (uint256 minor, uint256 patch) {
        minor = 1;
        patch = 0;
    }
}