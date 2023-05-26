// Froggy Friends by Fonzy & Mayan (www.froggyfriendsnft.com) Ribbit Item

//[email protected]@@@@........................
//.......................%@@@@@@@@@*[email protected]@@@#///(@@@@@...................
//[email protected]@@&(//(//(/(@@@.........&@@////////////@@@.................
//[email protected]@@//////////////@@@@@@@@@@@@/////@@@@/////@@@..............
//..................%@@/////@@@@@(////////////////////%@@@@/////#@@...............
//[email protected]@%//////@@@#///////////////////////////////@@@...............
//[email protected]@@/////////////////////////////////////////@@@@..............
//[email protected]@(///////////////(///////////////(////////////@@@............
//...............*@@/(///////////////&@@@@@@(//(@@@@@@/////////////#@@............
//[email protected]@////////////////////////(%&&%(///////////////////@@@...........
//[email protected]@@/////////////////////////////////////////////////&@@...........
//[email protected]@(/////////////////////////////////////////////////@@#...........
//[email protected]@@////////////////////////////////////////////////@@@............
//[email protected]@@/////////////////////////////////////////////#@@/.............
//................&@@@//////////////////////////////////////////@@@...............
//..................*@@@%////////////////////////////////////@@@@.................
//[email protected]@@@///////////////////////////////////////(@@@..................
//............%@@@////////////////............/////////////////@@@................
//..........%@@#/////////////..................... (/////////////@@@..............
//[email protected]@@////////////............................////////////@@@.............
//[email protected]@(///////(@@@................................(@@&///////&@@............
//[email protected]@////////@@@[email protected]@@///////@@@...........
//[email protected]@@///////@@@[email protected]@///////@@%..........
//.....(@@///////@@@[email protected]@/////(/@@..........

// Development help from Lexi

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/IERC1155MetadataURI.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IErc20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function transferFrom(address from,address to,uint256 amount) external returns (bool);
}

interface IErc721 {
    function balanceOf(address owner) external view returns (uint256);
}

contract RibbitItem is Context, ERC165, IERC1155, IERC1155MetadataURI, Ownable {
    using Address for address;

    // Variables
    string public name;
    string public symbol;
    string private baseUrl;
    string private contractUrl;
    uint256 decimals = 10**18;
    uint256 collabIdCounter = 1;
    uint256 idCounter;

    // Interfaces
    IErc20 ribbit;
    IErc721 froggyFriends;

    // Maps
    mapping(uint256 => uint256) price; 											// Item ID to price
    mapping(uint256 => uint256) percent; 										// Item ID to boost percentage
    mapping(uint256 => uint256) supply; 										// Item ID to supply
    mapping(uint256 => bool) boost; 											// Item ID to boost status (true if boost)
    mapping(uint256 => uint256) minted; 										// Item ID to minted supply
    mapping(uint256 => bool) onSale; 											// Item ID to sale status (true if on sale)
    mapping(uint256 => uint256) walletLimit; 									// Item ID to mint cap per wallet
    mapping(uint256 => address[]) holders; 										// Item ID to list of holder addresses
    mapping(uint256 => address) collabAddresses; 								// Item ID to collab account
    mapping(address => bool) approvedBurnAddress; 								// Address to burn state (true if approved)
    mapping(uint256 => mapping(address => uint256)) private _balances; 			// Token ID to map of address to balance
    mapping(address => mapping(address => bool)) private _operatorApprovals;    // Address to map of address to approval status (true if approved)
    mapping(uint256 => mapping(address => uint256)) private track; 				// Item ID to map of address to mint count
    mapping(address => mapping(uint256 => uint256)) private mintLimitCounter;	// Address to map of item ID to mint count

    constructor(string memory _name, string memory _symbol, string memory _baseUrl, string memory _contractUrl, address _ribbitAddress, address _froggyAddress) {
        name = _name;
        symbol = _symbol;
        baseUrl = _baseUrl;
        contractUrl = _contractUrl;
        ribbit = IErc20(_ribbitAddress);
        froggyFriends = IErc721(_froggyAddress);

        // Ribbit Items
        listItem(1, 200000, 6, true, 1);             // Golden Lily Pad
        listFriend(2, 5, 700, 201, true, true, 1);   // Rabbit Friend
        listFriend(3, 10, 1800, 151, true, true, 1); // Bear Friend
        listFriend(4, 15, 5000, 76, true, true, 1);  // Red Panda Friend
        listFriend(5, 20, 10000, 11, true, true, 1); // Cat Friend
        listFriend(6, 30, 100000, 6, true, true, 1); // Unicorn Friend
        listFriend(7, 35, 300000, 1, true, true, 1); // Golden Tiger Friend

        listCollabFriend(8, 10, 700, 5, true, true, 1, 0xba033D82c64DD514B184e2d1405cD395dfE6e706);   // Bao Society Friend
        listCollabFriend(9, 10, 700, 5, true, true, 1, 0x928f072C009727FbAd81bBF3aAa885f9fEa65fcf);   // Roo Troop Friend
        listCollabFriend(10, 5, 700, 5, true, true, 1, 0x67421C8622F8E38Fe9868b4636b8dC855347d570);   // Squishiverse Friend
        listCollabFriend(11, 5, 700, 5, true, true, 1, 0x1a2F71468F656E97c2F86541E57189F59951efe7);   // CryptoMories Friend
        listCollabFriend(12, 10, 1000, 2, true, true, 1, 0x0c2E57EFddbA8c768147D1fdF9176a0A6EBd5d83); // Kaiju Kings Friend

        // Froggy Milestones raffle reserved Ribbit Items
        adminMint(owner(), 1, 1); // Golden Lily Pad
        adminMint(owner(), 2, 1); // Rabbit Friend
        adminMint(owner(), 3, 1); // Bear Friend
        adminMint(owner(), 4, 1); // Red Panda Friend
        adminMint(owner(), 5, 1); // Cat Friend
        adminMint(owner(), 6, 1); // Unicorn Friend
    }

    /// @notice Bundle buy Ribbit Items
    /// @param ids list of ribbit item ids to buy
    /// @param amount list of ribbit item amounts
    function bundleBuy(uint256[] memory ids, uint256[] memory amount) public {
        require(ids.length == amount.length, "Ribbit item ID missing");
        for (uint256 i; i < ids.length; i++) {
            require(ids[i] > 0, "Ribbit item ID must not be zero");
            require(price[ids[i]] > 0, "Ribbit item price not set");
            uint256 saleAmount = amount[i] * price[ids[i]];
            require(ribbit.balanceOf(msg.sender) >= saleAmount, "Insufficient funds for purchase");
            require(onSale[ids[i]] == true, "Ribbit item not on sale");
            require(supply[ids[i]] > 0, "Ribbit item supply not set");
            require(walletLimit[ids[i]] > 0, "Ribbit item wallet limit not set");
            require(minted[ids[i]] + amount[i] <= supply[ids[i]], "Ribbit item supply exceeded");
            require(mintLimitCounter[msg.sender][ids[i]] + amount[i] <= walletLimit[ids[i]], "Ribbit item wallet limit exceeded");
            mintLimitCounter[msg.sender][ids[i]] += amount[i];
            if (track[ids[i]][msg.sender] < 1) {
                holders[ids[i]].push(msg.sender);
                track[ids[i]][msg.sender] = 1;
            }
            ribbit.transferFrom(msg.sender, address(this), saleAmount);
            minted[ids[i]] += amount[i];
            _mint(msg.sender, ids[i], amount[i], "");
        }
    }

    /// @notice Buy collab friend
    /// @param id the ribbit item id
    /// @param amount the amount of the ribbit item
    /// @param collabId the collab id of the ribbit item
    function collabBuy(uint256 id, uint256 amount, uint256 collabId) public {
        IErc721 collabNFT = IErc721(collabAddresses[collabId]);
        require(collabNFT.balanceOf(msg.sender) > 0, "Collab nft not owned");
        require(froggyFriends.balanceOf(msg.sender) > 0, "Froggy friend not owned");
        require(id > 0, "Ribbit item ID must not be zero");
        require(price[id] > 0, "Ribbit item price not set");
        uint256 saleAmount = amount * price[id];
        require(ribbit.balanceOf(msg.sender) >= saleAmount, "Insufficient funds for purchase");
        require(onSale[id] == true, "Ribbit item not on sale");
        require(supply[id] > 0, "Ribbit item supply not set");
        require(walletLimit[id] > 0, "Ribbit item wallet limit not set");
        require(minted[id] + amount <= supply[id], "Ribbit item supply exceeded");
        require(mintLimitCounter[msg.sender][id] + amount <= walletLimit[id], "Ribbit item wallet limit exceeded");
        mintLimitCounter[msg.sender][id] += amount;
        if (track[id][msg.sender] < 1) {
            holders[id].push(msg.sender);
            track[id][msg.sender] = 1;
        }
        ribbit.transferFrom(msg.sender, address(this), saleAmount);
        minted[id] += amount;
        _mint(msg.sender, id, amount, "");
    }

    /// @notice list friend ribbit item
    /// @param id the ribbit item id
    /// @param _percent the friend boost percentage
    /// @param _price the friend price in ether format
    /// @param _supply the friend supply
    /// @param _boost the friend boost status (true if is a boost)
    /// @param _onSale the friend sale status (true if is on sale)
    /// @param _walletLimit the friend wallet limit
    function listFriend(uint256 id, uint256 _percent, uint256 _price, uint256 _supply, bool _boost, bool _onSale, uint256 _walletLimit) public onlyOwner {
        require(id > idCounter, "Ribbit item ID exists");
        price[id] = _price * decimals;
        percent[id] = _percent;
        supply[id] = _supply;
        boost[id] = _boost;
        onSale[id] = _onSale;
        walletLimit[id] = _walletLimit;
        idCounter++;
    }

    /// @notice list collab friend item
    /// @param id the ribbit item id
    /// @param _percent the collab friend boost percentage
    /// @param _price the collab friend price in ether format
    /// @param _supply the collab friend supply
    /// @param _boost the collab friend boost status (true if is a boost)
    /// @param _onSale the collab friend sale status (true if is on sale)
    /// @param _walletLimit the collab friend wallet limit
    /// @param _collabAddress the collab NFT address
    function listCollabFriend(uint256 id, uint256 _percent, uint256 _price, uint256 _supply, bool _boost, bool _onSale, uint256 _walletLimit, address _collabAddress) public onlyOwner {
        require(id > idCounter, "Ribbit item ID exists");
        price[id] = _price * decimals;
        percent[id] = _percent;
        supply[id] = _supply;
        boost[id] = _boost;
        onSale[id] = _onSale;
        walletLimit[id] = _walletLimit;
        collabAddresses[collabIdCounter] = _collabAddress;
        collabIdCounter++;
        idCounter++;
    }

    /// @notice list ribbit item
    /// @param id the ribbit item id
    /// @param _price the ribbit item price in ether format
    /// @param _supply the ribbit item supply
    /// @param _onSale the ribbit item sale status (true if is on sale)
    /// @param _walletLimit the ribbit item wallet limit
    function listItem(uint256 id, uint256 _price, uint256 _supply, bool _onSale, uint256 _walletLimit) public onlyOwner {
        require(id > idCounter, "Ribbit item ID exists");
        price[id] = _price * decimals;
        supply[id] = _supply;
        onSale[id] = _onSale;
        walletLimit[id] = _walletLimit;
        idCounter++;
    }

    /// @notice sets the ribbit item price
    /// @param id the ribbit item id
    /// @param _price the ribbit item price in ether format
    function setPrice(uint256 id, uint256 _price) public onlyOwner {
        require(id <= idCounter, "ID does not exist");
        price[id] = _price * decimals;
    }

    /// @notice sets the ribbit item percent
    /// @param id the ribbit item id
    function setPercent(uint256 id, uint256 _percent) public onlyOwner {
        require(id <= idCounter, "ID does not exist");
        percent[id] = _percent;
    }

    /// @notice sets the ribbit item boost status (true if is boost)
    /// @param id the ribbit item id
    function setIsBoost(uint256 id, bool _isBoost) public onlyOwner {
        require(id <= idCounter, "ID does not exist");
        boost[id] = _isBoost;
    }

    /// @notice sets the ribbit item supply
    /// @param id the ribbit item id
    function setSupply(uint256 id, uint256 _supply) public onlyOwner {
        require(id <= idCounter, "ID does not exist");
        supply[id] = _supply;
    }

    /// @notice sets ribbit item sale status
    /// @param id the ribbit item id
    /// @param _onSale the ribbit item sale status (true if is on sale)
    function setOnSale(uint256 id, bool _onSale) public onlyOwner {
        require(id <= idCounter, "ID does not exist");
        onSale[id] = _onSale;
    }

    /// @notice sets ribbit item wallet limit
    /// @param id the ribbit item id
    /// @param _walletLimit the new wallet limit
    function setWalletLimit(uint256 id, uint256 _walletLimit) public onlyOwner {
        require(id <= idCounter, "ID does not exist");
        walletLimit[id] = _walletLimit;
    }

    /// @notice sets collab friend address
    /// @param collabId the collab friend ribbit item id
    /// @param _collabAddress the new collab friend address
    function setCollabAddress(uint256 collabId, address _collabAddress) public onlyOwner {
        require(collabId <= collabIdCounter, "ID does not exist");
        collabAddresses[collabId] = _collabAddress;
    }

    /// @notice sets address burn permissions
    /// @param add the address to update permissions for
    /// @param canBurn the permissions to grant (true if is approved for burning)
    function setApprovedBurnAddress(address add, bool canBurn) public onlyOwner {
        approvedBurnAddress[add] = canBurn;
    }

    /// @notice burns the amount of ribbit items specified
    /// @param from the address to burn the ribbit item from
    /// @param id the ribbit item id
    /// @param amount the amount of ribbit items to burn
    /// @dev burn function called by StakeFroggies.sol
    function burn(address from, uint256 id, uint256 amount) external {
        require(approvedBurnAddress[msg.sender] == true, "Address not approved for burning");
        _burn(from, id, amount);
    }

    /// @notice admin burns the entire ribbit item supply
    /// @param id the ribbit item id
    /// @dev only admin can burn the ribbit item supply
    /// @dev only use to burn temporary ribbit items
    function adminBurn(uint256 id) public onlyOwner {
        for (uint256 i; i < holders[id].length; i++) {
            _burn(holders[id][i], id, (balanceOf(holders[id][i], id)));
        }
    }

    /// @notice admin mint ribbit item to address
    /// @param account the address to mint the ribbit item to
    /// @param id the ribbit item id
    /// @param amount the amount of ribbit items
    function adminMint(address account, uint256 id, uint256 amount) public onlyOwner {
        require(minted[id] + amount <= supply[id], "Ribbit item supply exceeded");
        minted[id] += amount;
        _mint(account, id, amount, "");
    }

    /// @notice admin mints remaining ribbit items
    /// @param id the ribbit item id
    function adminMintAll(uint256 id) public onlyOwner {
        uint256 remaining = supply[id] - minted[id];
        require(minted[id] + remaining <= supply[id], "");
        require(remaining > 0, "Ribbit item supply reached");
        minted[id] += remaining;
        _mint(msg.sender, id, remaining, "");
    }

    /// @notice returns the ribbit item price by id in gwei format
    /// @param id the ribbit item id
    function getPrice(uint256 id) public view returns (uint256) {
        return price[id];
    }

    /// @notice returns the ribbit item boost percentage
    /// @param id the ribbit item id
    /// @dev boostPercentage function called by StakeFroggies.sol
    function boostPercentage(uint256 id) public view returns (uint256) {
        return percent[id];
    }

	/// @notice returns the max supply of a ribbit item
    /// @param id the ribbit item id
    function maxSupply(uint256 id) public view returns (uint256) {
        return supply[id];
    }

	/// @notice returns the ribbit item boost status (true if is boost)
    /// @param id the ribbit item id
    /// @dev isBoost function called by StakeFroggies.sol
    function isBoost(uint256 id) public view returns (bool) {
        return boost[id];
    }

	/// @notice returns the minted supply of a ribbit item
    /// @param id the ribbit item id
    function mintedSupply(uint256 id) public view returns (uint256) {
        return minted[id];
    }

    /// @notice returns the ribbit item sale status (true if is on sale)
    /// @param id the ribbit item id
    function isOnSale(uint256 id) public view returns (bool) {
        return onSale[id];
    }

    /// @notice returns the ribbit item wallet limit
    /// @param id the ribbit item id
    function getWalletLimit(uint256 id) public view returns (uint256) {
        return walletLimit[id];
    }

	/// @notice returns ribbit item properties by id
    /// @param id the ribbit item id
    /// @return item properties
    function item(uint256 id) public view returns (uint256, uint256, uint256, uint256, uint256, bool, bool) {
        return (
            getPrice(id), 
            boostPercentage(id), 
            mintedSupply(id),
            maxSupply(id),
            getWalletLimit(id),
            isBoost(id), 
            isOnSale(id)
        );
    }


	/// @notice returns the total number of ribbit items listed
    function totalListed() public view returns (uint256) {
        return idCounter;
    }

    /// @notice returns the number of collab friends listed
    function totalCollabs() public view returns (uint256) {
        return collabIdCounter-1;
    }

    /// @notice returns the collab address of a collab friend
    /// @param id the ribbit item id
    function collabAddress(uint256 id) public view returns (address) {
        return collabAddresses[id];
    }

	/// @notice returns the number of ribbit items an account owns
    /// @param account the address to check the balance of
    /// @param id the ribbit item id
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: address zero is not a valid owner");
        return _balances[id][account];
    }

    /// @notice returns ribbit item holders
    /// @param id the ribbit item id
    function itemHolders(uint256 id) public view returns (address[] memory) {
        return holders[id];
    }

    /// @notice sets the ribbit contract address
    /// @param account the ribbit address
    function setRibbitAddress(address account) public onlyOwner {
        ribbit = IErc20(account);
    }

    /// @notice sets the froggy friends contract address
    /// @param account the froggy friends address
    function setFroggyFriendsAddress(address account) public onlyOwner {
        froggyFriends = IErc721(account);
    }

    /// @notice withdraws ribbit balance from this contract to the admin account
    function withdrawRibbit() public onlyOwner {
        ribbit.transfer(msg.sender, ribbit.balanceOf(address(this)));
    }

    /// @notice returns the contract metdata url
    /// @dev i.e.(https://api.froggyfriendsnft.com/items/{_contractUrl})
    function contractURI() public view returns (string memory) {
        return string(abi.encodePacked(baseUrl, contractUrl));
    }

    /// @notice sets contract metdata uri
    /// @param _contractUrl the new contract uri path 
    /// @dev i.e. contract/metadata (https://api.froggyfriendsnft.com/items/{_contractUrl})
    function setContractURI(string memory _contractUrl) public onlyOwner {
        contractUrl = _contractUrl;
    }

    /// @dev uri fills the base url with the supplied item id
    /// @dev output format example if hosted on API https://api.froggyfriendsnft.com/item/{id}
    function uri(uint256 _tokenId) public view virtual override returns (string memory) {
        return string(abi.encodePacked(baseUrl, Strings.toString(_tokenId)));
    }

    /// @notice sets the metadata base url
    /// @param _baseUrl the metadata base url for example 'https://api.froggyfriendsnft.com/item/'
    function setURI(string memory _baseUrl) public onlyOwner {
        baseUrl = _baseUrl;
    }

    /// @dev See {IERC1155-balanceOfBatch}.
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids) public view virtual override returns (uint256[] memory) {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /// @dev See {IERC165-supportsInterface}.
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /// @dev See {IERC1155-setApprovalForAll}.
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /// @dev See {IERC1155-isApprovedForAll}.
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /// @dev See {IERC1155-safeTransferFrom}.
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes memory data) public virtual override {
        require(from == _msgSender() || isApprovedForAll(from, _msgSender()), "ERC1155: caller is not owner nor approved");

        _safeTransferFrom(from, to, id, amount, data);
        if (track[id][to] < 1) {
            holders[id].push(to);
            track[id][to] = 1;
        }

        if (balanceOf(from, id) == 0) {
            track[id][from] = 0;
            for (uint256 j; j < holders[id].length; j++) {
                if (holders[id][j] == from) {
                    holders[id][j] = holders[id][holders[id].length - 1];
                    holders[id].pop();
                    break;
                }
            }
        }
    }

    //// @dev See {IERC1155-safeBatchTransferFrom}.
    function safeBatchTransferFrom(address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) public virtual override {
        require(from == _msgSender() || isApprovedForAll(from, _msgSender()), "ERC1155: transfer caller is not owner nor approved");
        _safeBatchTransferFrom(from, to, ids, amounts, data);
        for (uint256 i; i < ids.length; i++) {
            if (track[ids[i]][to] < 1) {
                holders[ids[i]].push(to);
                track[ids[i]][to] = 1;
            }

            if (balanceOf(from, ids[i]) == 0) {
                track[ids[i]][from] = 0;
                for (uint256 j; j < holders[ids[i]].length; j++) {
                    if (holders[ids[i]][j] == from) {
                        holders[ids[i]][j] = holders[ids[i]][holders[ids[i]].length - 1];
                        holders[ids[i]].pop();
                        break;
                    }
                }
            }
        }
    }

    function _safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes memory data) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    function _safeBatchTransferFrom(address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    function _mint(address to, uint256 id, uint256 amount, bytes memory data) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function _burn(address from, uint256 id, uint256 amount) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(address from, uint256[] memory ids, uint256[] memory amounts) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(address owner, address operator, bool approved) internal virtual {
        require(owner != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal virtual {}

    function _afterTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal virtual {}

    function _doSafeTransferAcceptanceCheck(address operator, address from, address to, uint256 id, uint256 amount, bytes memory data) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
}