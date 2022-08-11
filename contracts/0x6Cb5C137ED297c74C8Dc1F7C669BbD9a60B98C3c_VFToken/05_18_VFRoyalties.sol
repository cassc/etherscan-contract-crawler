// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./IVFRoyalties.sol";
import "./VFAccessControl.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

contract VFRoyalties is IVFRoyalties, Context, ERC165 {
    //Struct for maintaining royalty information
    struct RoyaltyInfo {
        address receiver;
        uint96 royaltyFraction;
    }

    //Default royalty informations
    RoyaltyInfo private _defaultRoyaltyInfo;

    //Contract address to royalty information map
    mapping(address => RoyaltyInfo) private _contractRoyalInfo;

    //Contract for function access control
    VFAccessControl private _controlContract;

    /**
     * @dev Initializes the contract by setting a `controlContractAddress`, `defaultReceiver`,
     * and `defaultFeeNumerator` for the royalties contract.
     */
    constructor(
        address controlContractAddress,
        address defaultReceiver,
        uint96 defaultFeeNumerator
    ) {
        _controlContract = VFAccessControl(controlContractAddress);
        setDefaultRoyalty(defaultReceiver, defaultFeeNumerator);
    }

    modifier onlyRole(bytes32 role) {
        _controlContract.checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165)
        returns (bool)
    {
        return
            interfaceId == type(IVFRoyalties).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IVFRoyalties-setControlContract}.
     */
    function setControlContract(address controlContractAddress)
        external
        onlyRole(_controlContract.getAdminRole())
    {
        require(
            IERC165(controlContractAddress).supportsInterface(
                type(IVFAccessControl).interfaceId
            ),
            "Contract does not support required interface"
        );
        _controlContract = VFAccessControl(controlContractAddress);
    }

    /**
     * @dev See {IVFRoyalties-royaltyInfo}.
     */
    function royaltyInfo(
        uint256,
        address contractAddress,
        uint256 salePrice
    ) external view returns (address receiver, uint256 royaltyAmount) {
        RoyaltyInfo memory contractRoyaltyInfo = _contractRoyalInfo[
            contractAddress
        ];

        if (contractRoyaltyInfo.receiver == address(0)) {
            contractRoyaltyInfo = _defaultRoyaltyInfo;
        }

        royaltyAmount =
            (salePrice * contractRoyaltyInfo.royaltyFraction) /
            _feeDenominator();

        return (contractRoyaltyInfo.receiver, royaltyAmount);
    }

    /**
     * @dev See {IVFRoyalties-setDefaultRoyalty}.
     */
    function setDefaultRoyalty(address receiver, uint96 feeNumerator)
        public
        virtual
        onlyRole(_controlContract.getAdminRole())
    {
        require(
            feeNumerator <= _feeDenominator(),
            "ERC2981: royalty fee will exceed salePrice"
        );
        require(receiver != address(0), "ERC2981: invalid receiver");

        _defaultRoyaltyInfo = RoyaltyInfo(receiver, feeNumerator);
    }

    /**
     * @dev See {IVFRoyalties-deleteDefaultRoyalty}.
     */
    function deleteDefaultRoyalty()
        external
        virtual
        onlyRole(_controlContract.getAdminRole())
    {
        delete _defaultRoyaltyInfo;
    }

    /**
     * @dev See {IVFRoyalties-setContractRoyalties}.
     */
    function setContractRoyalties(
        address contractAddress,
        address receiver,
        uint96 feeNumerator
    ) external onlyRole(_controlContract.getAdminRole()) {
        require(
            feeNumerator <= _feeDenominator(),
            "ERC2981: royalty fee will exceed salePrice"
        );
        require(receiver != address(0), "ERC2981: invalid receiver");

        _contractRoyalInfo[contractAddress] = RoyaltyInfo(
            receiver,
            feeNumerator
        );
    }

    /**
     * @dev See {IVFRoyalties-resetContractRoyalty}.
     */
    function resetContractRoyalty(address contractAddress)
        external
        virtual
        onlyRole(_controlContract.getAdminRole())
    {
        delete _contractRoyalInfo[contractAddress];
    }

    /**
     * @dev Get the fee denominator
     */
    function _feeDenominator() internal pure virtual returns (uint96) {
        return 10000;
    }
}