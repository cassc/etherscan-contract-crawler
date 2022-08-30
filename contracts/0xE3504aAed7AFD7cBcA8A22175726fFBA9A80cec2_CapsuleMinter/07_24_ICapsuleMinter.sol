// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./IGovernable.sol";

interface ICapsuleMinter is IGovernable {
    struct SingleERC20Capsule {
        address tokenAddress;
        uint256 tokenAmount;
    }

    struct MultiERC20Capsule {
        address[] tokenAddresses;
        uint256[] tokenAmounts;
    }

    struct SingleERC721Capsule {
        address tokenAddress;
        uint256 id;
    }

    struct MultiERC721Capsule {
        address[] tokenAddresses;
        uint256[] ids;
    }

    struct MultiERC1155Capsule {
        address[] tokenAddresses;
        uint256[] ids;
        uint256[] tokenAmounts;
    }

    function getMintWhitelist() external view returns (address[] memory);

    function getCapsuleOwner(address _capsule, uint256 _id) external view returns (address);

    function isMintWhitelisted(address _user) external view returns (bool);

    function multiERC20Capsule(address _capsule, uint256 _id) external view returns (MultiERC20Capsule memory _data);

    function multiERC721Capsule(address _capsule, uint256 _id) external view returns (MultiERC721Capsule memory _data);

    function multiERC1155Capsule(address _capsule, uint256 _id)
        external
        view
        returns (MultiERC1155Capsule memory _data);

    function singleERC20Capsule(address _capsule, uint256 _id) external view returns (address _token, uint256 _amount);

    function mintSimpleCapsule(
        address _capsule,
        string memory _uri,
        address _receiver
    ) external payable;

    function burnSimpleCapsule(address _capsule, uint256 _id) external;

    function mintSingleERC20Capsule(
        address _capsule,
        address _token,
        uint256 _amount,
        string memory _uri,
        address _receiver
    ) external payable;

    function burnSingleERC20Capsule(address _capsule, uint256 _id) external;

    function mintSingleERC721Capsule(
        address _capsule,
        address _token,
        uint256 _id,
        string memory _uri,
        address _receiver
    ) external payable;

    function burnSingleERC721Capsule(address _capsule, uint256 _id) external;

    function mintMultiERC20Capsule(
        address _capsule,
        address[] memory _tokens,
        uint256[] memory _amounts,
        string memory _uri,
        address _receiver
    ) external payable;

    function burnMultiERC20Capsule(address _capsule, uint256 _id) external;

    function mintMultiERC721Capsule(
        address _capsule,
        address[] memory _tokens,
        uint256[] memory _ids,
        string memory _uri,
        address _receiver
    ) external payable;

    function burnMultiERC721Capsule(address _capsule, uint256 _id) external;

    function mintMultiERC1155Capsule(
        address _capsule,
        address[] memory _tokens,
        uint256[] memory _ids,
        uint256[] memory _amounts,
        string memory _uri,
        address _receiver
    ) external payable;

    function burnMultiERC1155Capsule(address _capsule, uint256 _id) external;

    // Special permission functions
    function addToWhitelist(address _user) external;

    function removeFromWhitelist(address _user) external;

    function flushTaxAmount() external;

    function updateCapsuleMintTax(uint256 _newTax) external;
}