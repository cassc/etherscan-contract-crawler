// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./MintpegErrors.sol";
import "./interfaces/IMintpeg.sol";

/// @title Mintpeg Factory
/// @author Trader Joe
/// @notice Factory that creates Mintpeg contracts
contract MintpegFactory is Ownable {
    /// @notice Emitted on createMintpeg()
    /// @param mintpeg Address of deployed mintpeg
    /// @param name Mintpeg (ERC721) name
    /// @param symbol Mintpeg (ERC721) symbol
    /// @param projectOwner The project owner
    /// @param royaltyReceiver Royalty fee collector
    /// @param royaltyFee Royalty fee numerator
    event MintpegCreated(
        address indexed mintpeg,
        string name,
        string symbol,
        address indexed projectOwner,
        address indexed royaltyReceiver,
        uint96 royaltyFee
    );

    /// @notice Mintpeg contract to be cloned
    address public mintpegImplementation;

    /// @notice Array of all deployed mintpeg addresses
    address[] public allMintpegs;

    /// @notice Mapping of adresses (deployer) to created mintpegs
    mapping(address => address[]) public createdMintpegs;

    /// @notice Emmited on setMintpegImplementation()
    /// @param mintpegImplementation implementation of mintpeg
    event SetMintpegImplementation(address indexed mintpegImplementation);

    /// @notice Function for creating mintpegs
    /// @param _name ERC721 name
    /// @param _symbol ERC721 symbol
    /// @param _royaltyReceiver Royalty fee collector
    /// @param _feePercent Royalty fee numerator; denominator is 10,000. So 500 represents 5%
    function createMintpeg(
        string memory _name,
        string memory _symbol,
        address _royaltyReceiver,
        uint96 _feePercent
    ) public {
        if (mintpegImplementation == address(0)) {
            revert MintpegFactory__InvalidMintpegImplementation();
        }
        address mintpeg = Clones.clone(mintpegImplementation);
        IMintpeg(mintpeg).initialize(
            _name,
            _symbol,
            msg.sender,
            _royaltyReceiver,
            _feePercent
        );

        allMintpegs.push(mintpeg);
        createdMintpegs[msg.sender].push(mintpeg);

        emit MintpegCreated(
            address(mintpeg),
            _name,
            _symbol,
            msg.sender,
            _royaltyReceiver,
            _feePercent
        );
    }

    /// @notice Set address for mintpegImplementation
    /// @param _mintpegImplementation New mintpegImplementation
    function setMintpegImplementation(address _mintpegImplementation)
        external
        onlyOwner
    {
        if (_mintpegImplementation == address(0)) {
            revert MintpegFactory__InvalidMintpegImplementation();
        }

        mintpegImplementation = _mintpegImplementation;
        emit SetMintpegImplementation(_mintpegImplementation);
    }

    /// @notice Function to get number of mintpegs deployed by an address
    /// @param _deployer Address of mintpeg(s) deployer
    function getNumberOfMintpegsCreated(address _deployer)
        external
        view
        returns (uint256)
    {
        return createdMintpegs[_deployer].length;
    }

    /// @notice Function to get number of mintpegs deployed
    /// @return uint256 number of all mintpegs deployed
    function getTotalMintpegsCount() external view returns (uint256) {
        return allMintpegs.length;
    }

    /// @notice Function to get address of deployed mintpeg at given index
    /// @dev Should be used with getNumberOfMintpegsCreated() to prevent running into
    /// out-of-range index errors
    /// @param _deployer Address of mintpeg(s) deployer
    /// @param _createdMintpegIndex Index of Mintpeg to be returned
    /// @return address Address of the Mintpeg implementation at given index
    function getMintpegCreatedAtIndex(
        address _deployer,
        uint256 _createdMintpegIndex
    ) external view returns (address) {
        return createdMintpegs[_deployer][_createdMintpegIndex];
    }
}