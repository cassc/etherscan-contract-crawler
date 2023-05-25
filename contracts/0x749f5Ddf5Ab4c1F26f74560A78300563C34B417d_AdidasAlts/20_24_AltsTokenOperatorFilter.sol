// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract AltsTokenOperatorFilter is Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping(address => bool) private approvedContracts;

    mapping(uint256 => EnumerableSet.AddressSet) private contractsAddresses;

    uint256 public globalERC721ChildrenLimit = 9;

    mapping(address => uint256) private childTokenLimits;

    /// @dev contract => tokenId => limit
    mapping(address => mapping(uint256 => uint256))
        private child1155TokenLimits;

    uint256 public contractCount = 0;

    uint256 public constant TOTAL_TOKEN_TYPES = 3;

    constructor() {}

    function changeERC721AndERC20Limit(
        address _childContract,
        uint256 _limit
    ) public onlyOwner {
        childTokenLimits[_childContract] = _limit;
    }

    function changeERC1155Limit(
        address _childContract,
        uint256 _tokenId,
        uint256 _limit
    ) public onlyOwner {
        child1155TokenLimits[_childContract][_tokenId] = _limit;
    }

    function changeGlobalERC721ChildrenLimit(uint256 _value) public onlyOwner {
        globalERC721ChildrenLimit = _value;
    }

    /**
     * @dev function adds new contracts to list of approved contracts
     * @param _tokenType support 3 types, Type 0 = ERC20, 1 = ERC721, 2 = ERC1155
     * @param _childContract child token contract address
     * @param _tokenId tokenId is used for 1155 contracts
     * @param _limit limit is used for ERC20 and 1155 contracts which have a balance.
     */
    function addContract(
        uint256 _tokenType,
        address _childContract,
        uint256 _tokenId,
        uint256 _limit
    ) public onlyOwner {
        require(_tokenType < TOTAL_TOKEN_TYPES, "Not a valid supported type.");
        require(!approvedContracts[_childContract], "Contract already exist");
        approvedContracts[_childContract] = true;
        unchecked {
            contractCount++;
        }
        if (_tokenType == 2) {
            child1155TokenLimits[_childContract][_tokenId] = _limit;
        } else {
            childTokenLimits[_childContract] = _limit;
        }
        contractsAddresses[_tokenType].add(_childContract);
    }

    /**
     * @dev function removes a contract from list of approved contracts
     * @param _tokenType support 3 types, Type 0 = ERC20, 1 = ERC721, 2 = ERC1155
     * @param _childContract child token contract address
     */
    function removeContract(
        uint256 _tokenType,
        address _childContract
    ) public onlyOwner {
        require(_tokenType < TOTAL_TOKEN_TYPES, "Not a valid supported type.");
        require(approvedContracts[_childContract], "Contract doesn't exist");
        approvedContracts[_childContract] = false;
        unchecked {
            contractCount--;
        }
        contractsAddresses[_tokenType].remove(_childContract);
    }

    /**
     * @dev function returns the contract limit
     * @param _childContract child token contract address
     */
    function getContractLimit(
        address _childContract
    ) public view returns (uint256) {
        return childTokenLimits[_childContract];
    }

    /**
     * @dev function returns the 1155 contract limit
     * @param _childContract child token contract address
     * @param _tokenId child token id
     */
    function get1155ContractLimit(
        address _childContract,
        uint256 _tokenId
    ) public view returns (uint256) {
        return child1155TokenLimits[_childContract][_tokenId];
    }

    /**
     * @dev function returns whether contract is on approved list
     * @param _childContract child token contract address
     */
    function isContractApproved(
        address _childContract
    ) public view returns (bool) {
        //If the contract is present/added then it is an approved contract
        return approvedContracts[_childContract];
    }

    /**
     * @dev function returns a list of all approved child contract addresses this is a very small list so gas should not be an issue.
     */
    function getAllChildContracts() public view returns (address[] memory) {
        address[] memory contractList = new address[](contractCount);
        uint256 index;
        unchecked {
            for (uint256 i = 0; i < TOTAL_TOKEN_TYPES; i++) {
                for (uint j = 0; j < contractsAddresses[i].length(); j++) {
                    contractList[index] = contractsAddresses[i].at(j);
                    index++;
                }
            }
        }
        return contractList;
    }

    /**
     * @dev function returns a list of type approved child contract addresses
     */
    function getTypeChildContracts(
        uint256 _type
    ) public view returns (address[] memory) {
        return contractsAddresses[_type].values();
    }
}