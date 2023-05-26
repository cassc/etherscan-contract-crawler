// SPDX-License-Identifier: MIT
/*
            ___        _               _             
           / _ \ _ __ (_)__   __ __ _ | |_  ___      
          / /_)/| '__|| |\ \ / // _` || __|/ _ \     
         / ___/ | |   | | \ V /| (_| || |_|  __/     
         \/     |_|   |_|  \_/_ \__,_| \__|\___|     
      /\/\    ___  _ __ ___  | |__    ___  _ __  ___ 
     /    \  / _ \| '_ ` _ \ | '_ \  / _ \| '__|/ __|
    / /\/\ \|  __/| | | | | || |_) ||  __/| |   \__ \
    \/    \/ \___||_| |_| |_||_.__/  \___||_|   |___/
             ___                     _               
            / __\_ __  _   _  _ __  | |_  ___        
           / /  | '__|| | | || '_ \ | __|/ _ \       
          / /___| |   | |_| || |_) || |_| (_) |      
          \____/|_|    \__, || .__/  \__|\___/       
                 ___  _|___/ |_|_                    
                / __\| | _   _ | |__                 
               / /   | || | | || '_ \                
              / /___ | || |_| || |_) |               
              \____/ |_| \__,_||_.__/    
          Crypto Club Global https://cc-gbl.io/
                                             
*/

pragma solidity 0.8.2;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/IERC1155MetadataURI.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

/// @custom:security-contact [email protected]
/// @title Crypto Club London NFT tokens
/// @notice Modified ERC-1155 contract to function more as an ERC721 but with improved efficient minting capabilities
contract PMCC1155 is Context, ERC165, IERC2981, IERC1155, IERC1155MetadataURI, ReentrancyGuard, Ownable, Pausable {
    using Counters for Counters.Counter;
    using Address for address;

    /// @dev Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;
    /// @dev Mapping from accounts to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;
    /// @dev Mapping from accounts to whitelist totals
    mapping(address => uint256) private _whiteListTotals;

    /// @dev Used as the URI for all token types by relying on ID substitution
    string private _uri;

    /// @dev Make NFT tokens enumerable
    Counters.Counter private _tokenIdCounter;

    /// @dev Cap supply
    uint256 maxSupply = 5000;

    /** 
    @dev Initially 5% royalty is expected, but can be changed with setRoyaltyFee(uint256 fee). Specified out of 10 000;
    this is converted to a percentage, but is set to 10 000 for improved accuracy for decimal places as Solidity does
    not handle floats.
    */
    uint256 private _royaltyFee = 500;

    /// @dev royalty to be paid to specific address
    address private _royaltyReceiver;

    /// @dev initial token prices
    uint256 _diamondPrice = 400000000000000000;
    uint256 _platinumPrice = 480000000000000000;

    /// @dev sale stage variable: 0 - founder, 1 - whitelist, 2 - public; starts at 0
    uint256 _stage = 0;

    constructor(string memory base_) {
        _setURI(base_);
        setRoyaltyReceiver(owner());
    }

    /// @dev Function to set the base URI
    function setURI(string calldata newuri) public onlyOwner {
        _setURI(newuri);
    }

    /// @notice Public function to retrieve the contract description for OpenSea
    function contractURI() public view returns (string memory) {
        return string(abi.encodePacked(_uri, "contract.json"));
    }

    /// @notice Public functions to get the total supply
    function totalSupply() public view returns (uint256) {
        uint256 tokenId = _tokenIdCounter.current();
        return tokenId;
    }

    /// @dev Function to pause all transfers
    function pause() public onlyOwner {
        _pause();
    }

    /// @dev Function to allow all transfers
    function unpause() public onlyOwner {
        _unpause();
    }

    /** @dev Function to add list of addresses to whiteList
    each address is mapped to the number of tokens it is allowed to
    mint, which is initially a maximum of 3.
    */
    function addToWhitelist(address[] calldata addressList) public onlyOwner {
        for (uint256 i = 0; i < addressList.length; i++) {
            _whiteListTotals[addressList[i]] = 3;
        }
    }

    /// @notice Function to check if an address is on the whitelist
    function checkOnWhitelist(address candidate_) public view returns (uint256) {
        return _whiteListTotals[candidate_];
    }

    /// @notice Mints multiple tokens at the same time provided price, sale, and supply cap are acceptable
    function mintBatch(
        address to,
        uint256 number,
        bytes memory data
    ) external payable nonReentrant whenNotPaused {
        // uint256 stage = _stage;
        uint256 currentTokenId = _tokenIdCounter.current();
        require((number > 0), "PMCC: must mint at least one token");
        require(((number + currentTokenId) <= maxSupply), "PMCC: request exceeds maxSupply");
        if (msg.sender != owner()) {
            require((_stage > 0), "PMCC: public minting not yet open");
            require((number <= 3), "PMCC: minting limited to maximum 3 tokens");
            require(msg.value == getMintingPrice(number), "PMCC: price must be equal to current getMintingPrice");
            if (_stage == 1) {
                // revert if we are in whitelist period and minter is not on the whitelist and is not owner
                require((_whiteListTotals[msg.sender] >= number), "PMCC: sender has insufficient whitelist allowance");
                _whiteListTotals[msg.sender] = _whiteListTotals[msg.sender] - number;
            }
        }
        uint256[] memory ids = new uint256[](number);
        uint256[] memory amount = new uint256[](number);
        for (uint256 i = 0; i < number; i++) {
            _tokenIdCounter.increment();
            ids[i] = _tokenIdCounter.current();
            amount[i] = 0x00000000000000000000000000000001;
        }
        _mintBatch(to, ids, amount, data);
    }

    /// @dev Allows owner to trigger withdrawal of contract funds to the royalty address
    function withdraw() public whenNotPaused {
        uint256 balance = address(this).balance;
        require((balance > 0), "PMCC: no balance to withdraw");
        Address.sendValue(payable(_royaltyReceiver), balance);
    }

    /// @notice Returns cost of minting a token, which is based on the tokenId range
    function getMintingPrice(uint256 amount) public view returns (uint256) {
        // we want the price of the next token, so add 1
        uint256 tokenId = _tokenIdCounter.current() + 1;
        uint256 _price;
        if (tokenId < 301) {
            _price = 0;
        } else if (tokenId < 1301) {
            _price = _diamondPrice;
        } else {
            _price = _platinumPrice;
        }
        // if minting accross the diamond/platinum threshold the minter gets a bargain
        return _price * amount;
    }

    // Sets new prices for minting diamond and platinum tokens
    function setMintingPrice(uint256 diamond_, uint256 platinum_) public virtual onlyOwner {
        _diamondPrice = diamond_;
        _platinumPrice = platinum_;
    }

    /// @dev Sets the current sale stage
    function setSaleStage(uint256 stage_) public virtual onlyOwner {
        _stage = stage_;
    }

    /// @notice  Gets the current sale stage
    function getSaleStage() public view returns (uint256) {
        return _stage;
    }

    /// @dev Returns a uint256 as a string
    function uint2str(uint256 _i) internal pure returns (string memory str) {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 length;
        while (j != 0) {
            length++;
            j /= 10;
        }
        bytes memory bstr = new bytes(length);
        uint256 k = length;
        j = _i;
        while (j != 0) {
            bstr[--k] = bytes1(uint8(48 + (j % 10)));
            j /= 10;
        }
        return string(bstr);
    }

    /// @notice  Returns the metadata URI for tokenId
    function uri(uint256 tokenId) public view virtual override returns (string memory) {
        return string(abi.encodePacked(_uri, uint2str(tokenId), ".json"));
    }

    /// @dev Sets the recommended royalty percentage 0-10000
    function setRoyaltyFee(uint256 fee) public onlyOwner {
        require(fee <= 10000, "PMCC: royalty cannot be greater than 100%");
        _royaltyFee = fee;
    }

    /// @notice Retrieve recommended royalty payment as per EIP-2981
    function royaltyInfo(uint256, uint256 _salePrice)
        public
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        return (_royaltyReceiver, (_salePrice * _royaltyFee) / 10000);
    }

    /// @dev Change receiving address for royalties
    function setRoyaltyReceiver(address newReceiver) public virtual onlyOwner {
        require(newReceiver != address(0), "PMCC: new royalty receiver cannot be the zero address");
        _royaltyReceiver = newReceiver;
    }

    // This section is @openzeppelin/contracts/token/ERC1155/ERC1155.sol
    // copied with irrelevant sections removed

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: balance query for the zero address");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(_msgSender() != operator, "ERC1155: setting approval status for self");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, _asSingletonArray(id), _asSingletonArray(amount), data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
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

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types
     *
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
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
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual whenNotPaused {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
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

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
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