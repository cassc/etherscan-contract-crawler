// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "@openzeppelin/contracts-upgradeable/utils/Create2Upgradeable.sol";

import "./ERC721BurnableV3.sol";

contract ERC721BurnableFactoryV3 is Initializable {
    event Deployed(address indexed creator, address indexed newContract);

    address public implementation;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() public initializer {
        implementation = address(new ERC721BurnableV3());
    }

    function createERC721Burnable(
        string memory name_,
        string memory symbol_,
        string memory baseTokenURI_,
        address royaltyReceiver_,
        uint96 royaltyBps_,
        uint256 initialSupply_,
        address initialSupplyReceiver_,
        address gaslessListingManager_,
        address contractOwner_,
        bytes4 salt_
    ) external returns (address) {
        address proxy = Create2Upgradeable.deploy(
            0,
            _computeDeploymentSalt(contractOwner_, salt_),
            _prepareDeploymentBytecode(
                name_,
                symbol_,
                baseTokenURI_,
                royaltyReceiver_,
                royaltyBps_,
                initialSupply_,
                initialSupplyReceiver_,
                gaslessListingManager_
            )
        );

        ERC721BurnableV3(proxy).transferOwnership(contractOwner_);

        emit Deployed(msg.sender, proxy);
        return proxy;
    }

    function computeERC721BurnableAddress(
        string memory name_,
        string memory symbol_,
        string memory baseTokenURI_,
        address royaltyReceiver_,
        uint96 royaltyBps_,
        uint256 initialSupply_,
        address initialSupplyReceiver_,
        address gaslessListingManager_,
        address contractOwner_,
        bytes4 salt_
    ) external view returns (address) {
        return
            Create2Upgradeable.computeAddress(
                _computeDeploymentSalt(contractOwner_, salt_),
                keccak256(
                    _prepareDeploymentBytecode(
                        name_,
                        symbol_,
                        baseTokenURI_,
                        royaltyReceiver_,
                        royaltyBps_,
                        initialSupply_,
                        initialSupplyReceiver_,
                        gaslessListingManager_
                    )
                )
            );
    }

    function _prepareDeploymentBytecode(
        string memory name_,
        string memory symbol_,
        string memory baseTokenURI_,
        address royaltyReceiver_,
        uint96 royaltyBps_,
        uint256 initialSupply_,
        address initialSupplyReceiver_,
        address gaslessListingManager_
    ) internal view returns (bytes memory) {
        // https://ethereum.stackexchange.com/questions/78738/passing-constructor-arguments-to-the-create-assembly-instruction-in-solidity;
        return
            abi.encodePacked(
                type(ERC1967Proxy).creationCode,
                abi.encode(
                    implementation,
                    abi.encodeCall(
                        ERC721BurnableV3(address(0)).initialize,
                        (
                            name_,
                            symbol_,
                            baseTokenURI_,
                            royaltyReceiver_,
                            royaltyBps_,
                            initialSupply_,
                            initialSupplyReceiver_,
                            gaslessListingManager_
                        )
                    )
                )
            );
    }

    /**
     * @dev Computes the bytes32 salt value to be passed to create2.
     */
    function _computeDeploymentSalt(address contractOwner_, bytes4 userSalt_) internal pure returns (bytes32) {
        return bytes32(bytes.concat(bytes20(contractOwner_), bytes8(0), bytes4(userSalt_)));
    }
}