//SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Address.sol";

/// @title Prompt
/// @author Burak Arıkan & Sam Hart
/// @notice Extends the ERC721 non-fungible token standard to enable verifiable collaborative authorship

contract Prompt is ERC721 {

    /// ============ Events ============

    event SessionCreated(uint256 tokenId, address contributor, address reservedAddress);
    event MemberAdded(uint256 tokenId, address account);
    event Contributed(uint256 tokenId, string contributionURI, address creator, uint256 price);
    event PriceSet(uint256 tokenId, address contributor, uint256 price);
    event PaymentReleased(address to, uint256 amount);

    /// ============ Structs ============

    struct Contribution {
        uint256 createdAt;
        uint256 price;
        address payable creator;
        string contributionURI;
    }

    /// ============ Mutable storage ============

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    mapping (uint256 => uint8) public memberCount;                             // memberCount[tokenId]
    mapping (uint256 => uint8) public contributionCount;                       // contributionCount[tokenId]
    mapping (uint256 => bool) public minted;                                   // minted[tokenId]
    mapping (uint256 => address) public reservedFor;                           // reservedFor[tokenId]
    mapping (uint256 => address[]) public members;                             // members[tokenId]
    mapping (address => uint256[]) public createdSessions;                     // createdSessions[address]
    mapping (uint256 => mapping (address => bool)) public membership;          // membership[tokenId][address]
    mapping (uint256 => mapping (address => Contribution)) public contributed; // contributed[tokenId][address]
    mapping (address => uint256[]) public contributedTokens;                   // contributedTokens[address]
    mapping (address => bool) public allowlist;                                // allowlist[address]
    mapping(uint256 => string) private _tokenURIs;                             // _tokenURIs[tokenId]

    mapping(address => uint256) private _balances;                             // _balances[account]
    mapping(address => uint256) private _released;                             // _released[account]

    /// ============ Immutable storage ============

    uint256 immutable public memberLimit;
    uint256 immutable public totalSupply;
    uint256 immutable public sessionLimitPerAccount;
    uint256 immutable public baseMintFee;
    uint256 immutable public mintFeeRate;
    address payable feeAddress;

    /// ============ Constructor ============

    /// @notice Creates a new Prompt NFT contract
    /// @param tokenName name of NFT
    /// @param tokenSymbol symbol of NFT
    /// @param _memberLimit member limit of each NFT
    /// @param _totalSupply total NFTs to mint
    /// @param _sessionLimitPerAccount max number of NFTs a member can create
    /// @param _baseMintFee in wei per NFT
    /// @param _mintFeeRate in percentage per NFT
    /// @param _feeAddress where mint fees are paid
    constructor(
        string memory tokenName,
        string memory tokenSymbol,
        uint256 _memberLimit,
        uint256 _totalSupply,
        uint256 _sessionLimitPerAccount,
        uint256 _baseMintFee,
        uint256 _mintFeeRate,
        address payable _feeAddress
    ) ERC721(
        tokenName,
        tokenSymbol
    ) {
        require(_memberLimit >= 2, "_memberLimit cannot be smaller than 2");
        require(_totalSupply > 0, "_totalSupply cannot be 0");
        require(_sessionLimitPerAccount > 0, "_sessionLimitPerAccount cannot be 0");
        require(_baseMintFee > 0, "_baseMintFee cannot be 0");
        require(_mintFeeRate > 0, "_mintFeeRate cannot be 0");
        require(_feeAddress != address(0), "feeAddress cannot be null address");

        memberLimit = _memberLimit;
        totalSupply = _totalSupply;
        sessionLimitPerAccount = _sessionLimitPerAccount;
        baseMintFee = _baseMintFee;
        mintFeeRate = _mintFeeRate;
        feeAddress = _feeAddress;
        allowlist[msg.sender] = true;
    }

    /// ============ Modifiers ============

    modifier isAllowed() {
        require (allowlist[msg.sender],
            'account is not in allowlist');
        _;
    }
    modifier onlyMemberOf(uint256 _tokenId) {
        require(membership[_tokenId][msg.sender],
            'not a session member');
        _;
    }
    modifier canCreateSession() {
        require (createdSessions[msg.sender].length < sessionLimitPerAccount,
            'account reached session limit');
        _;
    }
    modifier isNotEmpty(string memory _content) {
        require(bytes(_content).length != 0,
            'URI cannot be empty');
        _;
    }
    modifier memberNotContributed(uint256 _tokenId) {
        require (contributed[_tokenId][msg.sender].creator == address(0),
            'address already contributed');
        _;
    }
    modifier memberContributed(uint256 _tokenId) {
        require (contributed[_tokenId][msg.sender].creator == msg.sender,
            'address is not the creator of this contribution');
        _;
    }
    modifier isLastContribution(uint _tokenId) {
        require(contributionCount[_tokenId] == memberLimit - 1,
            'is not the last contribution');
        _;
    }
    modifier isFinalized(uint _tokenId) {
        require(contributionCount[_tokenId] == memberLimit,
            'not all members contributed or session has not ended yet');
        _;
    }
    modifier isNotMinted(uint _tokenId) {
        require(!minted[_tokenId],
            'session already minted');
        _;
    }

    /// ============ Functions ============

    /// @notice Create a session with tokenID. A session becomes mintable when all members contributed.
    /// @param _reservedAddress If set (optional), only this address can mint. Can be used for commissioned work.
    /// @param _members List of addresses who can contribute
    /// @param _contributionURI The first contribution metadata to the session
    /// @param _contributionPrice The first contribution price
    function createSession(
        address _reservedAddress,
        address[] calldata _members,
        string calldata _contributionURI,
        uint256 _contributionPrice
    )
        external
        isNotEmpty(_contributionURI)
        isAllowed()
        canCreateSession()
    {
        require(_tokenIds.current() < totalSupply, "reached token supply limit");
        require(_members.length <= memberLimit, "reached member limit");
        // require(_endsAt > block.timestamp, "quit living in the past");

        uint256 newTokenId = _tokenIds.current();

        uint256 length = _members.length;
        for (uint256 i=0; i < length;) {
            require(_members[i] != address(0), 'address cannot be null address');
            require(!membership[newTokenId][_members[i]], 'address is already a member of session');
            membership[newTokenId][_members[i]] = true;
            memberCount[newTokenId]++;
            members[newTokenId].push(_members[i]);
            allowlist[_members[i]] = true;
            unchecked { ++i; }
        }

        if (_reservedAddress != address(0)) {
            reservedFor[newTokenId] = _reservedAddress;
        }

        createdSessions[msg.sender].push(newTokenId);

        contributed[newTokenId][msg.sender] = Contribution(block.timestamp, _contributionPrice, payable(msg.sender), _contributionURI);
        contributedTokens[msg.sender].push(newTokenId);
        contributionCount[newTokenId]++;

        _setTokenURI(newTokenId, _contributionURI);

        _tokenIds.increment();

        emit SessionCreated(newTokenId, msg.sender, _reservedAddress);
    }

    /// @notice msg.sender contributes to a session with tokenId, contribution URI and price
    /// @param _tokenId The session to contribute
    /// @param _contributionURI Contribution metadata
    /// @param _contributionPrice Contribution price
    function contribute(
        uint256 _tokenId,
        string calldata _contributionURI,
        uint256 _contributionPrice
    )
        external
        onlyMemberOf(_tokenId)
        memberNotContributed(_tokenId)
        isNotEmpty(_contributionURI)
        isNotMinted(_tokenId)
    {
        contributed[_tokenId][msg.sender] = Contribution(block.timestamp, _contributionPrice, payable(msg.sender), _contributionURI);
        contributedTokens[msg.sender].push(_tokenId);
        contributionCount[_tokenId]++;

        _setTokenURI(_tokenId, _contributionURI);

        emit Contributed(_tokenId, _contributionURI, msg.sender, _contributionPrice);
    }

    /// @notice Set price of the msg.sender's contribution to a session, if not yet minted
    /// @param _tokenId The session of contribution
    /// @param _price New contribution price
    function setPrice(uint256 _tokenId, uint256 _price)
        external
        memberContributed(_tokenId)
        isNotMinted(_tokenId)
    {
        Contribution storage _contribution = contributed[_tokenId][msg.sender];
        _contribution.price = _price;

        emit PriceSet(_tokenId, msg.sender, _contribution.price);
    }

    /// @notice Anyone can mint paying the total
    /// @param _tokenId The session to mint
    function mint(uint256 _tokenId)
        external
        payable
        isFinalized(_tokenId)
    {
        if (reservedFor[_tokenId] != address(0)) {
            require(reservedFor[_tokenId] == msg.sender, "Mint is reserved for another address");
        }

        uint256 mintFee = baseMintFee;
        uint256 totalPrice = 0;

        Contribution[] memory contributions = getContributions(_tokenId);

        uint256 length = contributions.length;
        for (uint256 i=0; i < length;) {
            totalPrice += contributions[i].price;
            unchecked { ++i; }
        }
        if (totalPrice > 0) {
            mintFee = totalPrice * mintFeeRate / 100;
        }
        require(msg.value == totalPrice + mintFee, "Payment must be equal to listing price + mint fee");

        if (totalPrice > 0) {
            for (uint256 i=0; i < length;) {
                if (contributions[i].price > 0) {
                    _balances[contributions[i].creator] = _balances[contributions[i].creator] + contributions[i].price;
                    // contributions[i].creator.transfer(contributions[i].price);
                }
                unchecked { ++i; }
            }
        }

        minted[_tokenId] = true;

        Address.sendValue(feeAddress, mintFee);
        // feeAddress.transfer(mintFee);

        _safeMint(msg.sender, _tokenId);
    }

     /**
     * @notice Triggers a transfer to `account` of the amount of Ether they are owed,
     * according to their balance and their previous withdrawals.
     */
    function withdraw(address payable account) public virtual {
        require(balance(account) > 0, "Account has no balance");

        uint256 payment = releasable(account);

        require(payment != 0, "Account is not due payment");

        _released[account] += payment;
        // _balances[account] -= payment;

        Address.sendValue(account, payment);
        emit PaymentReleased(account, payment);
    }

    /// ============ Internal functions ============

    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        _tokenURIs[tokenId] = _tokenURI;
    }

    /// ============ Read-only functions ============

    function contractURI() public pure returns (string memory) {
        return "https://exquisitecorpse.prompts.studio/contract-metadata.json";
    }

    /**
     * @dev Get the amount of Eth held by an account.
     */
    function balance(address account) public view returns (uint256) {
        return _balances[account];
    }

    /**
     * @notice Get the amount of payee's releasable Eth.
     */
    function releasable(address account) public view returns (uint256) {
        return _balances[account] - _released[account];
    }

    /**
     * @notice Get the amount of Eth already released to a payee.
     */
    function released(address account) public view returns (uint256) {
        return _released[account];
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "URI query for nonexistent token");
        return _tokenURIs[tokenId];
    }

    /// @notice Get current count of minted tokens
    /// @return Returns number
    function tokenCount() external view virtual returns (uint256) {
        return _tokenIds.current();
    }

    /// @notice Check if an address is member of a session
    /// @return Returns true or false
    function isMember(uint256 _tokenId, address _account) external view virtual returns (bool) {
        return membership[_tokenId][_account];
    }

    /// @notice Check if all session members contributed
    /// @return Returns true or false
    function isCompleted(uint256 _tokenId) external view virtual returns (bool) {
        return contributionCount[_tokenId] == memberLimit;
    }

    /// @notice Check if account can create a new session
    /// @return Returns true or false
    function accountCanCreateSession(address _account) external view virtual returns (bool) {
        return createdSessions[_account].length < sessionLimitPerAccount;
    }

    /// @notice Get sessions initiated by an account
    /// @return Returns tokenIds
    function sessionCountByAccount(address _account)  external view virtual returns (uint256[] memory) {
        return createdSessions[_account];
    }

    /// @notice Get tokens contributed by an account
    /// @return Returns tokenIds
    function getContributedTokens(address _account) external view virtual returns (uint256[] memory) {
        return contributedTokens[_account];
    }

    /// @notice Get contributions of a token
    /// @return Returns contributions
    function getContributions(uint256 _tokenId) internal view returns (Contribution[] memory) {
        Contribution[] memory contributions_arr = new Contribution[](members[_tokenId].length);
        for (uint256 i=0; i < members[_tokenId].length; i++) {
            contributions_arr[i] = (contributed[_tokenId][members[_tokenId][i]]);
        }
        return contributions_arr;
    }

    /// @notice Get session data
    /// @return Returns (owner: address, tokenURI: string, members: address[], contributions: Contribution[], reserved: address)
    function getSession(uint256 _tokenId) external view virtual
        returns (
            address,
            string memory,
            address[] memory,
            Contribution[] memory,
            address
        )
    {
        string memory tokenuri = "";
        address sessionOwner = address(0);
        if (minted[_tokenId]) {
            tokenuri = tokenURI(_tokenId);
            sessionOwner = ownerOf(_tokenId);
        }
        return(
            sessionOwner,
            tokenuri,
            members[_tokenId],
            getContributions(_tokenId),
            reservedFor[_tokenId]
        );
    }
}