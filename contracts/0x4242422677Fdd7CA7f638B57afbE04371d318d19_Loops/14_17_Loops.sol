pragma solidity ^0.8.1;

//   █████ ██ ██ ██   ██  ███████
//   ██    ██ ██ ██   ██       ██    █   ███ ███ ███   ███ ███ █ ██ ███ ███ ███ ███ ███
//   ██ █████ ██ ██ █████ ██ ████    █   █ █ █ █ █ █   █   █ █ █ ██  █  █ █ █ █ █    █
//   ██    ██ ██      ██  ██         █   █ █ █ █ ███   █   █ █ ██ █  █  ██  ███ █    █
//   ██    ██ ██      ██  ███████    ███ ███ ███ █     ███ ███ █  █  █  █ █ █ █ ███  █

import "./Address.sol";
import "./EnumerableMap.sol";
import "./EnumerableSet.sol";
import "./SafeMath.sol";
import "./Context.sol";
import "./Ownable.sol";
import "./Strings.sol";

import "./IERC165.sol";
import "./ERC165Storage.sol";
import "./IERC721Enumerable.sol";
import "./IERC721Metadata.sol";
import "./IERC721Receiver.sol";
import "./IERC20.sol";
import "./IDUST.sol";

/**
 * @dev Loops (a ERC721 non-fungible token)
 */
contract Loops is Context, Ownable, ERC165Storage, IERC721Enumerable, IERC721Metadata {
    using SafeMath for uint256;
    using Address for address;
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableMap for EnumerableMap.UintToAddressMap;

    // Public variables
    string  public constant LOOPS_PROOF             = "9a87b113c77c7cdfedbbf644194914432a704073c836f9783a79696b088c62fa";
    uint256 public constant LOOP_SALESTART_TS       = 1617460944; // Sat Apr 03 2021 14:42:24 UTC
    uint256 public constant LOOP_CHANGE_NAME_PRICE  = 1024000000000000000000;
    uint256 public constant LOOP_MINT_REWARD        = 2048000000000000000000;
    uint256 public constant LOOP_DESTROY_REWARD     = 4096000000000000000000;
    uint256 public constant LOOP_MAX_SUPPLY         = 10101;

    // Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    // which can be also obtained as `IERC721Receiver(0).onERC721Received.selector`
    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

    // Mapping from holder address to their (enumerable) set of owned tokens
    mapping (address => EnumerableSet.UintSet) private _holderTokens;

    // Enumerable mapping from token ids to their owners
    EnumerableMap.UintToAddressMap private _tokenOwners;

    // Mapping from token ID to approved address
    mapping (uint256 => address) private _tokenApprovals;

    // Mapping from token ID to name
    mapping (uint256 => string) private _tokenName;

    // Mapping if certain Loop is currently hidden from public
    mapping (uint256 => bool) private _loopHidden;

    // Mapping from owner to operator approvals
    mapping (address => mapping (address => bool)) private _operatorApprovals;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // DUST Token address
    address private _dustAddress;

    // Number of burned loops
    uint256 private _burnedLoops;

    /*
     *     bytes4(keccak256('balanceOf(address)')) == 0x70a08231
     *     bytes4(keccak256('ownerOf(uint256)')) == 0x6352211e
     *     bytes4(keccak256('approve(address,uint256)')) == 0x095ea7b3
     *     bytes4(keccak256('getApproved(uint256)')) == 0x081812fc
     *     bytes4(keccak256('setApprovalForAll(address,bool)')) == 0xa22cb465
     *     bytes4(keccak256('isApprovedForAll(address,address)')) == 0xe985e9c5
     *     bytes4(keccak256('transferFrom(address,address,uint256)')) == 0x23b872dd
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256)')) == 0x42842e0e
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256,bytes)')) == 0xb88d4fde
     *
     *     => 0x70a08231 ^ 0x6352211e ^ 0x095ea7b3 ^ 0x081812fc ^
     *        0xa22cb465 ^ 0xe985e9c5 ^ 0x23b872dd ^ 0x42842e0e ^ 0xb88d4fde == 0x80ac58cd
     */
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;

    /*
     * 0x5b5e139f ===
     *     bytes4(keccak256('name()')) ^
     *     bytes4(keccak256('symbol()')) ^
     *     bytes4(keccak256('tokenURI(uint256)'))
     */
    bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;

    /*
     *     bytes4(keccak256('totalSupply()')) == 0x18160ddd
     *     bytes4(keccak256('tokenOfOwnerByIndex(address,uint256)')) == 0x2f745c59
     *     bytes4(keccak256('tokenByIndex(uint256)')) == 0x4f6ccce7
     *
     *     => 0x18160ddd ^ 0x2f745c59 ^ 0x4f6ccce7 == 0x780e9d63
     */
    bytes4 private constant _INTERFACE_ID_ERC721_ENUMERABLE = 0x780e9d63;

    // Events
    event ChangedLoopName(uint256 indexed loopId, string newName);
    event MintedLoops(address minter, uint256 loopId, uint256 count);
    event DestroyedLoop(uint256 indexed loopId, address destroyer, string lastWords);
    event HiddenLoop(uint256 indexed loopId, bool isHidden);

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor (string memory cname, string memory csymbol, address dustAddress) {
        _name = cname;
        _symbol = csymbol;
        _dustAddress = dustAddress;
        _burnedLoops = 0;

        // register the supported interfaces to conform to ERC721 via ERC165
        _registerInterface(_INTERFACE_ID_ERC721);
        _registerInterface(_INTERFACE_ID_ERC721_METADATA);
        _registerInterface(_INTERFACE_ID_ERC721_ENUMERABLE);
    }

    /**
     * @dev Returns base token URI 
     */
    function baseTokenURI() public pure returns (string memory) {
        return "https://app.ai42.art/api/loop/";
    }

    /**
     * @dev Returns an URI for a given token ID
     * Throws if the token ID does not exist. May return an empty string.
     * @param tokenId uint256 ID of the token to query
     */
    function tokenURI(uint256 tokenId) external view returns (string memory) {
      require(_exists(tokenId));
      return string(abi.encodePacked(baseTokenURI(), Strings.toString(tokenId)));
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");

        return _holderTokens[owner].length();
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view override returns (address) {
        return _tokenOwners.get(tokenId, "ERC721: owner query for nonexistent token");
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view override returns (uint256) {
        return _holderTokens[owner].at(index);
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _tokenOwners.length().sub(_burnedLoops);
    }

    function mintedSupply() public view returns (uint256) {
        return _tokenOwners.length();
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view override returns (uint256) {
        (uint256 tokenId, ) = _tokenOwners.at(index);
        return tokenId;
    }

    /**
     * @dev Returns name of the NFT at index.
     */
    function tokenNameByIndex(uint256 index) public view returns (string memory) {
        return _tokenName[index];
    }

    /**
     * @dev check if the loop is hidden or not
     */
    function isHidden(uint256 index) public view returns(bool) {
        return _loopHidden[index];
    }

    /**
     * @dev Returns the current price for a Loop
     */
    function getCurrentPrice(uint256 count) public view returns (uint256) {
	require(block.timestamp >= LOOP_SALESTART_TS, "ERROR: sale not started yet");
        require((count > 0) && (count < 17), "ERROR: number of Loops must be between 1 and 16");
        require(mintedSupply() < LOOP_MAX_SUPPLY, "ERROR: all loops have been sold");

        uint currentNumOfLoops = mintedSupply();
        uint256 price;

        if (currentNumOfLoops < 1024) {         price = 80000000000000000;     // 0-1023     ... 0.08E
        } else if (currentNumOfLoops < 2048) {  price = 160000000000000000;    // 1023-2047  ... 0.16E
        } else if (currentNumOfLoops < 4096) {  price = 320000000000000000;    // 2048-4095  ... 0.32E
        } else if (currentNumOfLoops < 8192) {  price = 640000000000000000;    // 4096-8191  ... 0.64E
        } else if (currentNumOfLoops < 9216) {  price = 1280000000000000000;   // 8192-9215  ... 1.28E
        } else {                                price = 2560000000000000000;   // 9216-10100 ....2.56E
        }

        return price.mul(count);
    } 

    /**
    * @dev Buy a Loop
    */
    function mintLoop(uint256 count) public payable {
        require((count > 0) && (count < 17), "Number of Loops must be between 1 and 16");
        require(msg.value >= getCurrentPrice(count) , "Payment not enough for loops");

	uint mintStart = mintedSupply();

        for (uint i = 0; i < count; i++) {
            require(LOOP_MAX_SUPPLY >= mintedSupply().add(count), "Not enough Loops left");
            _safeMint(msg.sender, mintedSupply());
        }

        IDUST(_dustAddress).mint(msg.sender, count.mul(LOOP_MINT_REWARD));

        emit MintedLoops(msg.sender, mintStart, count);
    }

    /**
     * @dev hides or unhides a loop
     */
    function hideLoop(uint256 tokenId, bool hide) external {
        require(_msgSender() == ownerOf(tokenId), "ERC721: caller is not the owner");
        _loopHidden[tokenId] = hide;

        emit HiddenLoop(tokenId, hide);
    }


    /**
     * @dev Changes the Loop name, optimized for gas
     */
    function changeLoopName(uint256 tokenId, string memory newName) external {
        require(_msgSender() == ownerOf(tokenId), "ERC721: caller is not the owner");
        require(checkName(newName) == true, "ERROR: name does not follow rules");
        require(keccak256(bytes(newName)) != keccak256(bytes(_tokenName[tokenId])), "ERROR: name is the same");

        IDUST(_dustAddress).transferFrom(msg.sender, address(this), LOOP_CHANGE_NAME_PRICE);
        _tokenName[tokenId] = newName;
        IDUST(_dustAddress).burn(LOOP_CHANGE_NAME_PRICE);

        emit ChangedLoopName(tokenId, newName);
    }

    /**
     * @dev Burns `tokenId`. See {ERC721-_burn}.
     *
     * Requirements:
     *
     * - The caller must own `tokenId` or be an approved operator.
     * - Last words must be supplied.
     */
    function burn(uint256 tokenId, string memory lastWords) public virtual {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721Burnable: caller is not owner nor approved");
        require(checkName(lastWords) == true, "ERROR: name does not follow rules");

        _tokenName[tokenId] = lastWords;
        _burn(tokenId);
        IDUST(_dustAddress).mint(msg.sender, LOOP_DESTROY_REWARD);

	emit DestroyedLoop(tokenId, _msgSender(), lastWords);
    }

    /**
     * @dev Withdraw ether from this contract (Callable by owner)
    */
    function withdraw() external onlyOwner {
        address payable ownerPay = payable(owner());
        ownerPay.transfer(address(this).balance);
    }

    /**
     * @dev Withdraw stuck ERC20s from this contract (Callable by owner)
    */
    function withdrawStuckERC20(address token, uint256 amount) external onlyOwner {
        require(token != _dustAddress, 'ERROR: cannot remove dust tokens');
        IERC20(token).transfer(owner(), amount);
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(_msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view returns (bool) {
        return _tokenOwners.contains(tokenId);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     d*
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(address to, uint256 tokenId, bytes memory _data) internal virtual {
        _mint(to, tokenId);
        require(_checkOnERC721Received(address(0), to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _holderTokens[to].add(tokenId);

        _tokenOwners.set(tokenId, to);

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _holderTokens[owner].remove(tokenId);

        _tokenOwners.set(tokenId, address(0));

	_burnedLoops++;

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        require(ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _holderTokens[from].remove(tokenId);
        _holderTokens[to].add(tokenId);

        _tokenOwners.set(tokenId, to);

        emit Transfer(from, to, tokenId);
    }


    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data)
        private returns (bool)
    {
        if (!to.isContract()) {
            return true;
        }
        bytes memory returndata = to.functionCall(abi.encodeWithSelector(
            IERC721Receiver(to).onERC721Received.selector,
            _msgSender(),
            from,
            tokenId,
            _data
        ), "ERC721: transfer to non ERC721Receiver implementer");
        bytes4 retval = abi.decode(returndata, (bytes4));
        return (retval == _ERC721_RECEIVED);
    }

    function _approve(address to, uint256 tokenId) private {
        _tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual { }

    /**
     * @dev check if name is valid (ascii range 0x20-0x7E without leading/trailing spaces)
     */
    function checkName(string memory str) public pure returns (bool){
        bytes memory b = bytes(str);
        if (b.length == 0) return false; // not empty
        if (b.length > 24) return false; // max 24 chars 
        if (b[0] == 0x20) return false;  // no leading space
        if (b[b.length - 1] == 0x20) return false; // no trailing space

        for(uint i; i < b.length; i++) { // asci range 0x20 to 0x7E
	    if (b[i] > 0x7E || b[i] < 0x20)
		return false;
        }
        return true;
    }
}

