// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract Allowlists {
    struct Allowlist {
        string listName;
        uint baseAllowed;
        uint price;
    }

    Allowlist[] public allowlists;
    uint public currentList;
    bool public mintingPaused;
    bool public publicMint;
    uint public constant publicMintPrice = 100000000000000000;
    mapping(uint => mapping(address => uint)) public mintableQuantity;
    mapping(string => uint) public listIndices;

    event AllowlistAdded(
        string indexed listName,
        uint indexed baseAllowed,
        uint price,
        uint indexed index
    );

    event MintingPaused();

    event MintingUnpaused();

    event SetPublicMinting(bool oldStatus, bool newStatus);

    event UserMinted(
        address indexed account,
        uint indexed pricePerMint,
        string indexed listName,
        uint quantity
    );

    constructor() {
        currentList = 0;
        mintingPaused = true;
    }

    function getCurrentList() public view returns (string memory) {
        if (publicMint == true) return "public";

        return allowlists[currentList].listName;
    }

    function getMaxMintsAllowed(address account)
        public
        view
        returns (uint allowed)
    {
        return mintableQuantity[currentList][account];
    }

    function getPricePerMint() public view returns (uint pricePerMint) {
        if (publicMint == true) return publicMintPrice;
        return allowlists[currentList].price;
    }

    function getAllowlistIndex(string calldata listName)
        public
        view
        returns (uint listIndex)
    {
        uint _listIndex = listIndices[listName];
        require(_listIndex > 0, "Allowlists: Invalid list");
        return _listIndex - 1;
    }

    function getNumberOfLists() external view returns (uint listsLength) {
        return allowlists.length;
    }

    modifier canMint(uint quantity) {
        require(mintingPaused == false, "Allowlists: Minting is not Allowed");

        if (publicMint == false)
            require(
                quantity <= getMaxMintsAllowed(msg.sender),
                "Allowlists: Quantity More Than Allocated"
            );

        require(
            msg.value >= (getPricePerMint() * quantity),
            "Allowlists: Insufficient fee"
        );

        _;
    }

    function _pauseMinting() internal {
        require(mintingPaused == false, "Allowlists: Already Paused");
        mintingPaused = true;
        emit MintingPaused();
    }

    function _unPauseMinting() internal {
        require(mintingPaused == true, "Allowlists: Already Unpaused");
        mintingPaused = false;
        emit MintingUnpaused();
    }

    function _setPublicMinting(bool newStatus) internal {
        require(
            publicMint != newStatus,
            "Allowlists: Public Mint Already In This State"
        );
        bool oldStatus = publicMint;
        publicMint = newStatus;
        emit SetPublicMinting(oldStatus, newStatus);
    }

    function _createAllowlist(
        string calldata listName,
        uint baseAllowed,
        uint price
    ) internal {
        allowlists.push(Allowlist(listName, baseAllowed, price));
        listIndices[listName] = allowlists.length;
    }

    function _setCurrentList(uint listIndex) internal {
        require(
            listIndex < allowlists.length,
            "Allowlists: Invalid List Index"
        );
        require(!mintingPaused, "Allowlists: Minting Paused");
        currentList = listIndex;
    }

    function _setNextList() internal {
        _setCurrentList(currentList + 1);
    }

    function _addToAllowlist(
        uint listIndex,
        address[] memory accounts,
        uint[] memory maxAllowed
    ) internal {
        require(
            accounts.length == maxAllowed.length,
            "Allowlists: Array Lengths Mismatch"
        );

        uint baseAllowed = allowlists[listIndex].baseAllowed;
        for (uint i = 0; i < accounts.length; i++) {
            address account = accounts[i];
            if (mintableQuantity[listIndex][account] != 0) continue;
            if (maxAllowed[i] == 0)
                mintableQuantity[listIndex][account] = baseAllowed;
            else mintableQuantity[listIndex][account] = maxAllowed[i];
        }
    }

    function _removeFromAllowlist(uint listIndex, address account) internal {
        mintableQuantity[listIndex][account] = 0;
    }

    function _decreaseMintableQuantity(address account, uint quantity)
        internal
    {
        uint remaining = mintableQuantity[currentList][account];
        require(remaining - quantity >= 0, "Allowlists: Quantity Underflow");
        mintableQuantity[currentList][account] -= quantity;
    }
}