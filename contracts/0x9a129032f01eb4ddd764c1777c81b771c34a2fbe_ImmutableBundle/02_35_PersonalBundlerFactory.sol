// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.17;

import "@openzeppelin/contracts/proxy/Clones.sol";

import "./utils/Ownable.sol";

import "./PersonalBundler.sol";

/**
 * @title PersonalBundlerFactory
 * @author NFTfi
 * @dev
 */
contract PersonalBundlerFactory is Ownable {
    address public immutable personalBundlerImplementation;
    string public baseURI;

    mapping(address => bool) public personalBundlerExists;

    event PersonalBundlerCreated(address indexed instance, address indexed owner, address creator);

    /**
     * @param _admin admin address capable of setting URI
     * @param _customBaseURI - Base URI
     * @param _personalBundlerImplementation - deployed master copy of the personal bundler contract
     */
    constructor(
        address _admin,
        string memory _customBaseURI,
        address _personalBundlerImplementation
    ) Ownable(_admin) {
        baseURI = _customBaseURI;
        personalBundlerImplementation = _personalBundlerImplementation;
    }

    /**
     * @dev clones a new personal bundler contract
     *
     * @param _to - owner of the personal bundler
     */
    function createPersonalBundler(address _to) external returns (address) {
        address instance = Clones.clone(personalBundlerImplementation);
        personalBundlerExists[instance] = true;
        PersonalBundler(instance).initialize(owner(), _to, baseURI);
        emit PersonalBundlerCreated(instance, _to, msg.sender);
        return instance;
    }

    /**
     * @dev Sets baseURI.
     * @param _customBaseURI - Base URI
     */
    function setBaseURI(string memory _customBaseURI) external onlyOwner {
        baseURI = _customBaseURI;
    }
}