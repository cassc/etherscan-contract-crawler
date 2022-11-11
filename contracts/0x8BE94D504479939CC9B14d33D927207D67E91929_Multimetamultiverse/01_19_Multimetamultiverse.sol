// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "@prb/math/contracts/PRBMathUD60x18.sol";

import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@uniswap/v3-periphery/contracts/interfaces/IQuoter.sol";

import "./IMultimetamultiverse.sol";
import "./Utils.sol";

interface IERC20 {
    function transfer(address _to, uint _value) external returns (bool);
}

interface IUniswapRouter is ISwapRouter {
    function refundETH() external payable;
}

contract Multimetamultiverse is Initializable, IMultimetamultiverse, ERC721Upgradeable, OwnableUpgradeable {
    using PRBMathUD60x18 for uint;

    /**
     * State variables
     */

    IUniswapRouter public constant UNISWAP_ROUTER = IUniswapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);
    IQuoter public constant QUOTER = IQuoter(0xb27308f9F90D607463bb33eA1BeBb41C27CE5AB6);

    address private constant UNISWAP_TOKEN = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address private constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    // Developer fee
    uint public constant DEVELOPER_FEE = 100000000000000000;

    struct Token {
        bool lock; // Transfer lock
        uint price; // Token price (PRBMath view)
        uint created; // Created date
        uint projectId; // Project id
        uint revealTime; // Time for URI reveal
        uint value; // Current value of the token (PRBMath view)
        string uri; // Filename with extension
        address[] affiliates; // Addresses of affiliates
    }

    Token[] public tokens;

    struct ProjectGroup {
        address author; // Address of project's owner
        address[] tokenHolders; // Token holders
        mapping(address => bool) tokenHoldersHistory; // Token holders for all time (to avoid duplicating in tokenHolders array)
        mapping(address => uint) tokenHoldersBalance; // Balance of token holders
        mapping(address => uint) tokenHoldersShares; // Balance of token holders in `shares`
        uint totalShares; // Total `shares` amount for the project group
        mapping(address => bool) whitelistedAuthors; // Users who can create projects in project group
        bool onlyWhitelistedAuthors; // Flag that only whitelisted authors can add projects to this group
        bool projectLocked; // Flag for the opportunity to add new projects
    }

    ProjectGroup[] private projectGroups;

    struct Project {
        uint projectGroupId;
        address author; // Address of project's owner
        // 0 - amount of tokens which whitelisted users need to buy in order to have discount
        // 1 - purchase discount for whitelisted users after whitelisted period (PRBMath view)
        // 2 - amount of tokens which whitelisted users can purchase with the discount (after whitelisted period)
        // 3 - amount of tokens which whitelisted users can receive (during whitelisted period)
        uint[4] whitelist;
        bool onlyWhitelistedUsers; // If only whitelisted users can buy for this project
        mapping(address => bool) whitelistedUsers; // Whitelisted users
        mapping(address => uint) tokenDiscountBalance; // Balance of token holders purchased with the discount
        uint[6] royalty; // 0 - seller, 1 - buyer, 2 - reflection, 3 - author, 4 - token, 5 - affiliate. All in PRBMath view
        uint mintAmount; // Amount of tokens which can be minted
        uint mintPrice; // Price to mint the token
        uint revealTime; // Time for token URI reveal
        string revealURI; // URI which will be returned if token has not revealed yet
        mapping(address => bool) tokenURIEditors; // Users who can modify tokens URI
        string uri; // URI of the IPFS (or any other storage) folder, where all token metadata will be stored
        uint uriCounter; // A pointer to the current file (in the URI folder) that will be attached to the token during minting
        string uriExt; // File extension (in URI folder)
        bool mintLocked; // Flag for the opportunity to mint
        uint affiliateDepth; // Max number of affiliates to share affiliate royalty
    }

    Project[] private projects;

    // Locks
    bool public projectGroupLocked;
    bool public projectLocked;
    bool public mintLocked;

    // Minimum price of new tokens (in UNISWAP_TOKEN, PRBMath view)
    uint public minTokenPrice;

    // Global users who can create Project Groups / Projects if `onlyWhitelistedAuthors` mode is enabled
    mapping(address => bool) public whitelistedAuthors;

    bool public onlyWhitelistedAuthors;

    // Users who can't do anything
    mapping(address => bool) public bannedUsers;

    // Addresses with saving (in UNISWAP_TOKEN)
    mapping(address => uint) public savings;

    /**
     * EIP4907
     */

    struct UserInfo {
        address user; // Address of user role
        uint64 expires; // Unix timestamp
    }

    mapping(uint => UserInfo) internal _users;

    function initialize() public initializer {
        __ERC721_init("M3", "M3");
        __Ownable_init();

        onlyWhitelistedAuthors = true;
        minTokenPrice = 1000000000000000000;
    }

    /**
     * URI
     */

    function editTokenURI(uint tokenId, string calldata uri_) external userNotBanned {
        Token storage token = tokens[tokenId];
        Project storage project = projects[token.projectId];

        require(project.tokenURIEditors[msg.sender] || msg.sender == project.author || msg.sender == owner(), "NA"); // No access
        token.uri = uri_;

        emit TokenURIEdit(tokenId, token.uri);
    }

    function tokenURI(uint tokenId) override public view returns (string memory) {
        Token storage token = tokens[tokenId];
        Project storage project = projects[token.projectId];

        if (token.created + token.revealTime > block.timestamp) {
            return project.revealURI;
        }

        return string.concat(project.uri, token.uri);
    }

    /**
     * Locks
     */

    function setProjectGroupLocked(bool state) external onlyOwner {
        projectGroupLocked = state;
        emit ProjectGroupLockedEdit(state);
    }

    function setProjectLocked(bool state) external onlyOwner {
        projectLocked = state;
        emit ProjectLockedEdit(state);
    }

    function setMintLocked(bool state) external onlyOwner {
        mintLocked = state;
        emit MintLockedEdit(state);
    }

    /**
     * Mint
     */

    function mint(uint projectId, bool lock, uint price, uint amount, uint deadline, address affiliate) public userNotBanned payable {
        require(price >= minTokenPrice, "PW"); // Price wrong

        Project storage project = projects[projectId];
        ProjectGroup storage projectGroup = projectGroups[project.projectGroupId];

        if (msg.sender != owner()) {
            require(mintLocked == false && (project.mintLocked == false || msg.sender == project.author), "L"); // Locked
        }

        require(affiliate != msg.sender, "AS"); // Affiliate address must be different from sender
        require(amount > 0, "AW"); // Amount wrong

        // If mintAmount is less than 0, the transaction will automatically fail
        project.mintAmount -= amount;

        // Project whitelist mode checks
        if (project.onlyWhitelistedUsers == true && msg.sender != projectGroup.author) {
            require(project.whitelistedUsers[msg.sender], "NW"); // Not whitelisted
            require(projectGroup.tokenHoldersBalance[msg.sender] + amount <= project.whitelist[3], "ML"); // Mint limit
        }

        uint mintPrice;

        for (uint i = 0; i < amount; i++) {
            // Discount for whitelisted users after whitelisted period
            if (project.onlyWhitelistedUsers == false
            && project.whitelistedUsers[msg.sender]
            && projectGroup.tokenHoldersBalance[msg.sender] >= project.whitelist[0]
                && project.tokenDiscountBalance[msg.sender] < project.whitelist[2]
            ) {
                mintPrice = project.mintPrice - project.mintPrice.mul(project.whitelist[1]);
                project.tokenDiscountBalance[msg.sender]++;
            }
            else {
                mintPrice = project.mintPrice;
            }

            Token storage token = tokens.push();
            uint tokenId = tokens.length - 1;

            token.lock = lock;
            token.price = price;
            token.created = block.timestamp;
            token.projectId = projectId;
            token.revealTime = project.revealTime;
            token.uri = string.concat(StringsUpgradeable.toString(project.uriCounter++), project.uriExt);

            if (affiliate != address(0)) {
                token.affiliates.push(affiliate);
            }

            _safeMint(msg.sender, tokenId, "");
            handleFees(project.author, msg.sender, mintPrice, tokenId, deadline);
        }

        // Refund leftover ETH to user
        (bool success,) = msg.sender.call{value: address(this).balance}("");
        require(success, "RF"); // Refund failed
    }

    function setMinTokenPrice(uint price) external onlyOwner {
        minTokenPrice = price;
        emit MinTokenPriceEdit(price);
    }

    /**
     * Token
     */

    function editToken(uint tokenId, bool lock, uint price) external userNotBanned {
        require(ownerOf(tokenId) == msg.sender || msg.sender == owner(), "NO"); // Not owner
        require(price >= minTokenPrice, "PW"); // Price wrong

        Token storage token = tokens[tokenId];
        token.lock = lock;
        token.price = price;

        emit TokenEdit(tokenId, token.lock, token.price, token.projectId, token.revealTime, token.value);
    }

    function burn(uint tokenId) external userNotBanned {
        require(ownerOf(tokenId) == msg.sender || msg.sender == owner(), "NO"); // Not owner

        _burn(tokenId);

        Token storage token = tokens[tokenId];

        savings[msg.sender] += token.value;
        emit SavingsEdit(msg.sender, savings[msg.sender]);

        decreaseTokenHolderAmount(projects[token.projectId].projectGroupId, msg.sender);
        delete tokens[tokenId];
    }

    /**
     * Users
     */

    modifier userNotBanned() {
        require(bannedUsers[msg.sender] == false, "UB"); // User banned
        _;
    }

    function addBannedUserBatch(address[] calldata users) external onlyOwner {
        for (uint i = 0; i < users.length; i++) {
            bannedUsers[users[i]] = true;
        }

        emit BannedUsersAdd(users);
    }

    function removeBannedUserBatch(address[] calldata users) external onlyOwner {
        for (uint i = 0; i < users.length; i++) {
            delete bannedUsers[users[i]];
        }

        emit BannedUsersRemove(users);
    }

    /**
     * Project groups
     */

    modifier onlyProjectGroupAuthor(uint projectGroupId) {
        require(msg.sender == projectGroups[projectGroupId].author || msg.sender == owner(), "NA"); // Not author
        _;
    }

    function addProjectGroup(bool onlyWhitelistedAuthors_, bool projectLocked_) external userNotBanned {
        if (msg.sender != owner()) {
            require(projectGroupLocked == false, "L");
            require(onlyWhitelistedAuthors == false || whitelistedAuthors[msg.sender], "NW"); // Not whitelisted
        }

        ProjectGroup storage projectGroup = projectGroups.push();
        projectGroup.author = msg.sender;
        projectGroup.onlyWhitelistedAuthors = onlyWhitelistedAuthors_;
        projectGroup.projectLocked = projectLocked_;

        emit ProjectGroupEdit(projectGroups.length - 1, msg.sender, onlyWhitelistedAuthors_, projectLocked_);
    }

    function editProjectGroup(uint projectGroupId, bool onlyWhitelistedAuthors_, bool projectLocked_) external userNotBanned onlyProjectGroupAuthor(projectGroupId) {
        ProjectGroup storage projectGroup = projectGroups[projectGroupId];

        projectGroup.onlyWhitelistedAuthors = onlyWhitelistedAuthors_;
        projectGroup.projectLocked = projectLocked_;

        emit ProjectGroupEdit(projectGroupId, projectGroup.author, onlyWhitelistedAuthors_, projectLocked_);
    }

    function addProjectGroupWhitelistedAuthorBatch(uint projectGroupId, address[] calldata users) external onlyProjectGroupAuthor(projectGroupId) userNotBanned {
        for (uint i = 0; i < users.length; i++) {
            projectGroups[projectGroupId].whitelistedAuthors[users[i]] = true;
        }

        emit ProjectGroupWhitelistedAuthorsAdd(projectGroupId, users);
    }

    function removeProjectGroupWhitelistedAuthorBatch(uint projectGroupId, address[] calldata users) external onlyProjectGroupAuthor(projectGroupId) userNotBanned {
        for (uint i = 0; i < users.length; i++) {
            delete projectGroups[projectGroupId].whitelistedAuthors[users[i]];
        }

        emit ProjectGroupWhitelistedAuthorsRemove(projectGroupId, users);
    }

    /**
     * Projects
     */

    modifier onlyProjectAuthor(uint projectId) {
        require(msg.sender == projects[projectId].author || msg.sender == owner(), "NA"); // Not author
        _;
    }

    function addProject(
        uint projectGroupId,
        uint[4] calldata whitelist,
        bool onlyWhitelistedUsers,
        uint[6] calldata royalty,
        uint mintAmount,
        uint mintPrice,
        uint revealTime,
        string[3] calldata uri_,
        bool mintLocked_,
        uint affiliateDepth
    ) external {
        if (msg.sender != owner()) {
            require(projectLocked == false && projectGroups[projectGroupId].projectLocked == false, "L");
            require(msg.sender == projectGroups[projectGroupId].author || projectGroups[projectGroupId].onlyWhitelistedAuthors == false || projectGroups[projectGroupId].whitelistedAuthors[msg.sender], "NW");
        }

        Project storage project = projects.push();
        project.projectGroupId = projectGroupId;
        project.author = msg.sender;

        editProject(projects.length - 1, whitelist, onlyWhitelistedUsers, royalty, mintAmount, mintPrice, revealTime, uri_, mintLocked_, affiliateDepth);
    }

    function editProject(
        uint projectId,
        uint[4] calldata whitelist,
        bool onlyWhitelistedUsers,
        uint[6] calldata royalty,
        uint mintAmount,
        uint mintPrice,
        uint revealTime,
        string[3] calldata uri_,
        bool mintLocked_,
        uint affiliateDepth
    ) public userNotBanned onlyProjectAuthor(projectId) {
        require(whitelist[1] <= 1000000000000000000, "DW"); // Discount wrong
        require(royalty[0] + royalty[1] <= 1000000000000000000 && royalty[2] + royalty[3] + royalty[4] == 1000000000000000000 - DEVELOPER_FEE && royalty[5] <= 500000000000000000, "RW"); // Royalties wrong
        require(mintPrice >= minTokenPrice, "PW"); // Price wrong

        Project storage project = projects[projectId];

        project.whitelist = whitelist;
        project.onlyWhitelistedUsers = onlyWhitelistedUsers;
        project.royalty = royalty;
        project.mintAmount = mintAmount;
        project.revealTime = revealTime;
        project.mintPrice = mintPrice;
        project.revealURI = uri_[0];
        project.uri = uri_[1];
        project.uriExt = uri_[2];
        project.mintLocked = mintLocked_;
        project.affiliateDepth = affiliateDepth;

        emit ProjectEdit(projectId, project.projectGroupId, project.author, whitelist, onlyWhitelistedUsers, royalty, mintAmount, mintPrice, revealTime, uri_, mintLocked_, affiliateDepth);
    }

    function addProjectWhitelistedUserBatch(uint projectId, address[] calldata users) external onlyProjectAuthor(projectId) userNotBanned {
        for (uint i = 0; i < users.length; i++) {
            projects[projectId].whitelistedUsers[users[i]] = true;
        }

        emit ProjectWhitelistedUsersAdd(projectId, users);
    }

    function removeProjectWhitelistedUserBatch(uint projectId, address[] calldata users) external onlyProjectAuthor(projectId) userNotBanned {
        for (uint i = 0; i < users.length; i++) {
            delete projects[projectId].whitelistedUsers[users[i]];
        }

        emit ProjectWhitelistedUsersRemove(projectId, users);
    }

    function addProjectTokenURIEditorsBatch(uint projectId, address[] calldata users) external onlyProjectAuthor(projectId) userNotBanned {
        for (uint i = 0; i < users.length; i++) {
            projects[projectId].tokenURIEditors[users[i]] = true;
        }

        emit ProjectTokenURIEditorsAdd(projectId, users);
    }

    function removeProjectTokenURIEditorsBatch(uint projectId, address[] calldata users) external onlyProjectAuthor(projectId) userNotBanned {
        for (uint i = 0; i < users.length; i++) {
            delete projects[projectId].tokenURIEditors[users[i]];
        }

        emit ProjectTokenURIEditorsRemove(projectId, users);
    }

    /**
     * Authors
     */

    function addWhitelistedAuthorBatch(address[] calldata users) external onlyOwner {
        for (uint i = 0; i < users.length; i++) {
            whitelistedAuthors[users[i]] = true;
        }

        emit WhitelistedAuthorsAdd(users);
    }

    function removeWhitelistedAuthorBatch(address[] calldata users) external onlyOwner {
        for (uint i = 0; i < users.length; i++) {
            delete whitelistedAuthors[users[i]];
        }

        emit WhitelistedAuthorsRemove(users);
    }

    function setOnlyWhitelistedAuthors(bool state) external onlyOwner {
        onlyWhitelistedAuthors = state;
        emit OnlyWhitelistedAuthorsEdit(state);
    }

    /**
     * Transfer
     */

    function safeTransferFrom(address from, address to, uint tokenId, bytes memory data) public virtual override {
        transfer(from, to, tokenId, Utils.bytesToUint(data, 0));
    }

    function transfer(address from, address to, uint tokenId, uint deadline) public payable userNotBanned {
        Token storage token = tokens[tokenId];
        Project storage project = projects[token.projectId];

        if (msg.sender != owner()) {
            require(token.lock == false, "L"); // Locked
            require(project.onlyWhitelistedUsers == false, "NT"); // No transfer (whitelisted mode)
        }

        _safeTransfer(from, to, tokenId, "");
        decreaseTokenHolderAmount(project.projectGroupId, from);

        // Set token lock
        token.lock = true;

        handleFees(from, to, token.price, tokenId, deadline);

        // Refund leftover ETH to user
        (bool success,) = msg.sender.call{value: address(this).balance}("");
        require(success, "RF"); // Refund failed
    }

    function handleFees(address from, address to, uint price, uint tokenId, uint deadline) private {
        Token storage token = tokens[tokenId];
        Project storage project = projects[token.projectId];
        ProjectGroup storage projectGroup = projectGroups[project.projectGroupId];

        uint fees_buyer = price.mul(project.royalty[1]);

        if (price > 0) {
            ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams(WETH, UNISWAP_TOKEN, 3000, address(this), deadline, msg.value, 1, 0);

            UNISWAP_ROUTER.exactInputSingle{value: msg.value}(params);
            UNISWAP_ROUTER.refundETH();
        }

        // Count fees
        uint total_fees = fees_buyer + price.mul(project.royalty[0]);
        uint reflection_fees = total_fees.mul(project.royalty[2]);
        uint developer_fees = total_fees.mul(DEVELOPER_FEE);

        // Fees for smart contract developers and affiliates
        if (token.affiliates.length > 0 && token.affiliates.length <= project.affiliateDepth) {
            uint affiliate_fees = developer_fees.mul(project.royalty[5]);
            developer_fees -= affiliate_fees;

            uint affiliate_savings_i = 0;
            uint[] memory affiliate_savings = new uint[](token.affiliates.length);

            if (token.affiliates.length > 1)
            {
                // Initial affiliate receives half of the fee each time
                savings[token.affiliates[0]] += affiliate_fees.div(2000000000000000000);
                affiliate_savings[affiliate_savings_i++] = savings[token.affiliates[0]];

                uint affiliate_fees_buffer = affiliate_fees.div(2000000000000000000 * (token.affiliates.length - 1));

                for (uint i = 1; i < token.affiliates.length; i++)
                {
                    savings[token.affiliates[i]] += affiliate_fees_buffer;
                    affiliate_savings[affiliate_savings_i++] = savings[token.affiliates[i]];
                }
            }
            else
            {
                savings[token.affiliates[0]] += affiliate_fees;
                affiliate_savings[affiliate_savings_i++] = savings[token.affiliates[0]];
            }

            emit SavingsEditBatch(token.affiliates, affiliate_savings);

            if (token.affiliates.length < project.affiliateDepth)
            {
                token.affiliates.push(to);
            }
        }

        savings[address(this)] += developer_fees;

        // Fees for project author
        savings[project.author] += total_fees.mul(project.royalty[3]);

        // Add payment to the current token owner
        savings[from] += (price + fees_buyer) - total_fees;

        // Fees for token itself
        token.value += total_fees.mul(project.royalty[4]);
        emit TokenEdit(tokenId, token.lock, token.price, token.projectId, token.revealTime, token.value);

        // Reflection
        if (projectGroup.tokenHolders.length > 0) {
            uint event_i = 0;
            uint[] memory event_savings = new uint[](projectGroup.tokenHolders.length);

            for (uint i = 0; i < projectGroup.tokenHolders.length; i++) {
                savings[projectGroup.tokenHolders[i]] += projectGroup.tokenHoldersShares[projectGroup.tokenHolders[i]].div(projectGroup.totalShares).mul(reflection_fees);
                event_savings[event_i++] = savings[projectGroup.tokenHolders[i]];
            }

            emit SavingsEditBatch(projectGroup.tokenHolders, event_savings);
        }
        else {
            // Extra fees for project author
            savings[project.author] += reflection_fees;
        }

        emit SavingsEdit(address(this), savings[address(this)]);
        emit SavingsEdit(project.author, savings[project.author]);
        emit SavingsEdit(from, savings[from]);

        // Add token holder
        if (projectGroup.tokenHoldersHistory[to] == false) {
            projectGroup.tokenHolders.push(to);
            projectGroup.tokenHoldersHistory[to] = true;
        }

        // Increase token holder amount
        projectGroup.tokenHoldersBalance[to] += 1000000000000000000;
        setTokenHolderShares(project.projectGroupId, to);
    }

    function decreaseTokenHolderAmount(uint projectGroupId, address holder) private {
        projectGroups[projectGroupId].tokenHoldersBalance[holder] -= 1000000000000000000;
        setTokenHolderShares(projectGroupId, holder);
    }

    function setTokenHolderShares(uint projectGroupId, address holder) private {
        ProjectGroup storage projectGroup = projectGroups[projectGroupId];
        mapping(address => uint) storage holdersShares = projectGroup.tokenHoldersShares;
        mapping(address => uint) storage holdersBalance = projectGroup.tokenHoldersBalance;

        // Remove previous amount of holder shares from the total
        projectGroup.totalShares -= holdersShares[holder];

        if (holdersBalance[holder] < 8000000000000000000) {
            holdersShares[holder] = holdersBalance[holder].div(8000000000000000000);
        }
        else {
            Utils.PowerOfTwo memory power_of_two = Utils.getPowerOfTwo(holdersBalance[holder]);
            holdersShares[holder] = power_of_two.index + (holdersBalance[holder] - power_of_two.value).div(power_of_two.value);
        }

        // Add new amount of holder shares to the total
        projectGroup.totalShares += holdersShares[holder];
    }

    /**
     * Savings release
     */

    function releaseSavings(address from, address to, uint amount) external userNotBanned {
        require(from == msg.sender || msg.sender == owner(), "NO"); // Not owner

        // Reduce savings leaving the remainder
        savings[from] -= amount;
        emit SavingsEdit(from, savings[from]);

        IERC20 coin = IERC20(address(UNISWAP_TOKEN));
        coin.transfer(to, amount);
    }

    /**
     * Opportunity to get unused ETH from the exchange
     */

    receive() payable external {}

    /**
     * EIP4907
     */

    function setUser(uint tokenId, address user, uint64 expires) public virtual {
        require(_isApprovedOrOwner(msg.sender, tokenId), "NO"); // Not owner

        UserInfo storage info = _users[tokenId];
        info.user = user;
        info.expires = expires;

        emit UpdateUser(tokenId, user, expires);
    }

    /**
     * Get the user expires of a token.
     * If there is no user role of a token, it will return 0
     */
    function userExpires(uint tokenId) public view virtual returns (uint){
        return _users[tokenId].expires;
    }

    /**
     * Get the user role of a token
     */
    function userOf(uint tokenId) public view virtual returns (address) {
        if (uint(_users[tokenId].expires) >= block.timestamp) {
            return _users[tokenId].user;
        }

        return address(0);
    }

    function _beforeTokenTransfer(address from, address to, uint tokenId) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from != to && _users[tokenId].user != address(0)) {
            delete _users[tokenId];
            emit UpdateUser(tokenId, address(0), 0);
        }
    }
}