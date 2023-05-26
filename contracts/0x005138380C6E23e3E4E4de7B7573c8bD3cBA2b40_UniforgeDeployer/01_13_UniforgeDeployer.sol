// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { Ownable } from "openzeppelin/access/Ownable.sol";
import { UniforgeCollection } from "./UniforgeCollection.sol";

/**
 * @title Uniforge Deployer
 * @author Diego Carranza at Dapponics
 * @notice UniforgeDeployer is a contract factory that enables the
 * creation of UniforgeCollection contracts and contains methods to
 * interact with Uniforge platform. Visit uniforge.io for more info.
 * @notice UniforgeCollection is an optimized and universal token
 * contract that extends ERC721A with enforced royalty capabilities.
 */
contract UniforgeDeployer is Ownable {
    uint256 private _deployFee;
    uint256 private _collectionCounter;
    mapping(uint256 => address) private _collection;
    mapping(address => uint256) private _creatorDiscount;

    event DeployFeeUpdated(uint256 indexed deployFee);
    event NewCollectionCreated(address indexed collection);
    event NewCreatorDiscount(address indexed creator, uint256 indexed discount);

    // =============================================================
    //                          CONSTRUCTOR
    // =============================================================

    /**
     * @notice Transfers ownership to a new owner at the contract creation.
     * @param owner The address of the new owner.
     */
    constructor(address owner) {
        transferOwnership(owner);
    }

    // =============================================================
    //                   NEW COLLECTION DEPLOYMENT
    // =============================================================

    /**
     * @notice Transfers ownership to the contract creator and declares all the variables.
     * @param owner The address of the new owner of the contract.
     * @param name The name of the new ERC721 token.
     * @param symbol The symbol of the new ERC721 token.
     * @param baseURI The base Uniform Resource Identifier (URI) of the new ERC721 token.
     * @param mintFee The fee for minting a single token while the public sale is open.
     * @param mintLimit The maximum number of tokens that can be minted at once.
     * @param maxSupply The maximum total number of tokens that can be minted.
     * @param saleStart The timestamp representing the start time of the public sale.
     * @param royaltyReceiver The address of the new royalty receiver of the contract.
     * @param royaltyPercentage The percentage of the royalty for the ERC2981 standard.
     * @param royaltyEnforced The boolean that enables or disables the Operator Filter.
     */
    function deployNewCollection(
        address owner,
        string memory name,
        string memory symbol,
        string memory baseURI,
        uint256 mintFee,
        uint256 mintLimit,
        uint256 maxSupply,
        uint256 saleStart,
        address royaltyReceiver,
        uint96 royaltyPercentage,
        bool royaltyEnforced
    ) external payable {
        // `_discountPercentage` can not underflow as its minimum value is 1.
        // `_collectionCounter` is unlikely to overflow as its maximum value is (2^256)-1.
        unchecked{
            uint256 _discountPercentage = 100 - _creatorDiscount[msg.sender];
            uint256 _finalPrice = (_deployFee * _discountPercentage) / 100;
            if (msg.value < _finalPrice) revert UniforgeDeployer__NeedMoreETHSent();
     
            address _newCollection = address(
                new UniforgeCollection(
                    owner,
                    name,
                    symbol,
                    baseURI,
                    mintFee,
                    mintLimit,
                    maxSupply,
                    saleStart,
                    royaltyReceiver,
                    royaltyPercentage,
                    royaltyEnforced
                )
            );
            _collection[_collectionCounter] = address(_newCollection);
            _collectionCounter += 1;
            emit NewCollectionCreated(address(_newCollection));
        }
    }

    // =============================================================
    //                        ADMIN FUNCTIONS
    // =============================================================

    /**
     * @notice Allows the contract owner to set a new default deploy fee. 
     * @param fee The new deployment fee amount.
     */
    function setDeployFee(uint256 fee) external onlyOwner {
        _deployFee = fee;
        emit DeployFeeUpdated(fee);
    }

    /**
     * @notice Allows the contract owner to provide a discount to a creator.
     * @param creator The address of the creator.
     * @param percentage The discount percentage.
     */
    function setCreatorDiscount(address creator, uint256 percentage) external onlyOwner {
        if (percentage > 99) revert UniforgeDeployer__InvalidDiscount();
        _creatorDiscount[creator] = percentage;
        emit NewCreatorDiscount(creator, percentage);
    }

    /**
     * @notice Allows the contract owner to withdraw the ether balance of the contract.
     */
    function withdraw() external onlyOwner {
        (bool success,) = payable(msg.sender).call{value: address(this).balance}("");
        if (!success) revert UniforgeDeployer__TransferFailed();
    }

    // =============================================================
    //                         VIEW FUNCTIONS
    // =============================================================

    /**
     * @notice Returns the number of Uniforge Collections deployed through this contract.
     */
    function deployments() external view returns (uint256) {
        return _collectionCounter;
    }

    /**
     * @notice Returns the address of a specific deployed Uniforge Collection.
     * @param index The index of the deployed collection.
     */
    function deployment(uint256 index) external view returns (address) {
        return _collection[index];
    }

    /**
     * @notice Returns the deployment fee required to deploy a new Uniforge Collection.
     */
    function deployFee() external view returns (uint256) {
        return _deployFee;
    }

    /**
     * @notice Returns the discount percentage for a specific creator.
     * @param creator The address of the creator.
     */
    function creatorDiscount(address creator) external view returns (uint256) {
        return _creatorDiscount[creator];
    }

    /**
     * @notice Returns the final price required to deploy a new Uniforge Collection.
     * @param creator The address of the creator.
     */
    function creatorFee(address creator) external view returns (uint256) {
        // `_discountPercentage` can not underflow as its minimum value is 1.
        unchecked{
            uint256 _discountPercentage = 100 - _creatorDiscount[creator];
            return (_deployFee * _discountPercentage) / 100;
        }
    }
}

/**
 * @notice UniforgeDeployer custom errors.
 */
error UniforgeDeployer__NeedMoreETHSent();
error UniforgeDeployer__TransferFailed();
error UniforgeDeployer__InvalidDiscount();