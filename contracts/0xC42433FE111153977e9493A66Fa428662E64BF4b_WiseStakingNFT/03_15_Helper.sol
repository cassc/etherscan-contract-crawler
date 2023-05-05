// SPDX-License-Identifier: WISE

pragma solidity =0.8.19;

abstract contract Helper {

    address public owner;
    address public newOwner;

    event OwnershipTransferred(
        address indexed oldOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(
            msg.sender
        );
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(
            owner == msg.sender,
            "Helper: INVALID_OWNER"
        );
        _;
    }

    /**
     * @dev Allows to remove ownership.
     */
    function renounceOwnership()
        external
        onlyOwner
    {
        _transferOwnership(
            address(0)
        );
    }

    /**
     * @dev Decides who will be next owner.
     */
    function transferOwnership(
        address _newOwner
    )
        external
        onlyOwner
    {
        newOwner = _newOwner;
    }

    /**
     * @dev Allows to claim ownership.
     */
    function claimOwnership()
        external
    {
        require(
            msg.sender == newOwner,
            "Helper: INVALID_NEW_OWNER"
        );

        _transferOwnership(
            newOwner
        );
    }

    /**
     * @dev Performs ownership transfer.
     */
    function _transferOwnership(
        address _newOwner
    )
        internal
    {
        address oldOwner = owner;
        owner = _newOwner;

        emit OwnershipTransferred(
            oldOwner,
            newOwner
        );
    }

    /**
     * @dev Converts tokenId uint to string.
     */
    function _toString(
        uint256 _tokenId
    )
        internal
        pure
        returns (string memory str)
    {
        if (_tokenId == 0) {
            return "0";
        }

        uint256 j = _tokenId;
        uint256 length;

        while (j != 0) {
            length++;
            j /= 10;
        }

        bytes memory bstr = new bytes(
            length
        );

        uint256 k = length;
        j = _tokenId;

        while (j != 0) {
            bstr[--k] = bytes1(
                uint8(
                    48 + j % 10
                )
            );
            j /= 10;
        }

        str = string(
            bstr
        );
    }
}