// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

import "./CErc20.sol";
import "./CDelegateInterface.sol";

/**
 * @title Compound's CErc20Delegate Contract
 * @notice CTokens which wrap an EIP-20 underlying and are delegated to
 * @author Compound
 */
contract CErc20Delegate is CDelegateInterface, CErc20 {
  /**
   * @notice Called by the delegator on a delegate to initialize it for duty
   * @param data The encoded bytes data for any initialization
   */
  function _becomeImplementation(bytes memory data) public virtual override {
    require(msg.sender == address(this) || hasAdminRights(), "!self || !admin");
  }

  /**
   * @notice Called by the delegator on a delegate to forfeit its responsibility
   */
  function _resignImplementation() internal virtual {
    // Shh -- we don't ever want this hook to be marked pure
    if (false) {
      implementation = address(0);
    }
  }

  /**
   * @dev Internal function to update the implementation of the delegator
   * @param implementation_ The address of the new implementation for delegation
   * @param allowResign Flag to indicate whether to call _resignImplementation on the old implementation
   * @param becomeImplementationData The encoded bytes data to be passed to _becomeImplementation
   */
  function _setImplementationInternal(
    address implementation_,
    bool allowResign,
    bytes memory becomeImplementationData
  ) internal {
    // Check whitelist
    require(
      IFuseFeeDistributor(fuseAdmin).cErc20DelegateWhitelist(implementation, implementation_, allowResign),
      "!impl"
    );

    // Call _resignImplementation internally (this delegate's code)
    if (allowResign) _resignImplementation();

    address oldImplementation = implementation;
    implementation = implementation_;

    // add the extensions of the new implementation
    _updateExtensions();

    if (address(this).code.length == 0) {
      // cannot delegate to self with an external call when constructing
      _becomeImplementation(becomeImplementationData);
    } else {
      // Call _becomeImplementation externally (delegating to new delegate's code)
      _functionCall(
        address(this),
        abi.encodeWithSignature("_becomeImplementation(bytes)", becomeImplementationData),
        "!become"
      );
    }

    emit NewImplementation(oldImplementation, implementation);
  }

  function _updateExtensions() internal {
    address[] memory latestExtensions = IFuseFeeDistributor(fuseAdmin).getCErc20DelegateExtensions(implementation);
    address[] memory currentExtensions = LibDiamond.listExtensions();

    // don't update if they are the same
    if (latestExtensions.length == 1 && currentExtensions.length == 1 && latestExtensions[0] == currentExtensions[0])
      return;

    // removed the current (old) extensions
    for (uint256 i = 0; i < currentExtensions.length; i++) {
      LibDiamond.removeExtension(DiamondExtension(currentExtensions[i]));
    }
    // add the new extensions
    for (uint256 i = 0; i < latestExtensions.length; i++) {
      LibDiamond.addExtension(DiamondExtension(latestExtensions[i]));
    }
  }

  /**
   * @notice Called by the admin to update the implementation of the delegator
   * @param implementation_ The address of the new implementation for delegation
   * @param allowResign Flag to indicate whether to call _resignImplementation on the old implementation
   * @param becomeImplementationData The encoded bytes data to be passed to _becomeImplementation
   */
  function _setImplementationSafe(
    address implementation_,
    bool allowResign,
    bytes calldata becomeImplementationData
  ) external override {
    // Check admin rights
    require(hasAdminRights(), "!admin");

    // Set implementation
    _setImplementationInternal(implementation_, allowResign, becomeImplementationData);
  }

  /**
   * @notice Function called before all delegator functions
   * @dev Checks comptroller.autoImplementation and upgrades the implementation if necessary
   */
  function _prepare() external payable override {
    if (msg.sender != address(this) && ComptrollerV3Storage(address(comptroller)).autoImplementation()) {
      (address latestCErc20Delegate, bool allowResign, bytes memory becomeImplementationData) = IFuseFeeDistributor(
        fuseAdmin
      ).latestCErc20Delegate(implementation);
      if (implementation != latestCErc20Delegate) {
        _setImplementationInternal(latestCErc20Delegate, allowResign, becomeImplementationData);
      } else {
        _updateExtensions();
      }
    }
  }

  function contractType() external pure virtual override returns (string memory) {
    return "CErc20Delegate";
  }
}