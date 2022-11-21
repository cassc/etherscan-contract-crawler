//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./interfaces/IProtocolDirectory.sol";
import "./interfaces/IMember.sol";
import "./interfaces/IMembership.sol";
import "./interfaces/IMembershipFactory.sol";
import "./interfaces/IBlacklist.sol";

import "./libraries/TokenActions.sol";

import "./structs/MemberStruct.sol";
import "./structs/BackupApprovalStruct.sol";
import "./structs/MembershipStruct.sol";

// Errors definition
error OnlyWalletOfUser();
error UserNotTokenOwner();
error NotValidUID();
error UserExists();
error UserDoesNotExist();
error UserMustHaveWallet();
error TokensDifferentLength();
error RequireBackupApproval();
error RequireBackupWallet();
error MembershipNotActive();
error MembershipRequireTopup();
error NotFactoryAddress();
error StoringBackupFailed();

/**
 * @title Member Contract
 * @notice This contract contains logic for interacting with the
 * ecosystem and verifying ownership as well as the panic button
 * functionality and backup information (BackupPlan)
 *
 */

contract Member is
    IMember,
    Initializable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable
{
    /// @notice Mapping to return member when uid is passed
    mapping(string => member) public members;

    /// @notice UserMembershipAddress mapping for getting Membership contracts by user
    mapping(string => address) private UserMembershipAddress;

    /// @notice mapping for token backup Approvals for specific UID
    mapping(string => BackUpApprovals[]) private MemberApprovals;

    /// @notice Storing ApprovalId for different approvals stored
    uint88 private _approvalId;

    /// @dev address of the ProtocolDirectory
    address public directoryContract;

    /// @notice Variable to store all member information
    member[] public allMembers;

    /**
     * @notice memberCreated Event when creating member
     * @param uid string of dApp identifier for a user
     * @param dateCreated timestamp of event occurence
     *
     */
    event memberCreated(string uid, uint256 dateCreated);

    /**
     * @notice Event when updating primary wallet
     * @param uid string string of dApp identifier for a user
     * @param dateCreated uint256 timestamap of event occuring
     * @param wallets address[] list of wallets for the user
     * @param primaryWallet uint256 primary wallet for assets
     *
     */
    event walletUpdated(
        string uid,
        uint256 dateCreated,
        address[] backUpWallets,
        address[] wallets,
        uint256 primaryWallet
    );

    /**
     * @notice Event for Querying Approvals
     *
     * @param uid string of dApp identifier for a user
     * @param approvedWallet address of the wallet owning the asset
     * @param backupaddress address[] list of addresses containing assets
     * @param tokenId uint256 tokenId of asset being backed up
     * @param tokenAddress address contract of the asset being protectd
     * @param tokenType string i.e. ERC20 | ERC1155 | ERC721
     * @param tokensAllocated uint256 number of tokens to be protected
     * @param dateApproved uint256 timestamp of event happening
     * @param claimed bool status of the backupApproval
     * @param approvalId uint256 id of the approval being acted on
     * @param claimedWallet address of receipient of assets
     *
     *
     */
    event BackUpApprovalsEvent(
        string uid,
        address approvedWallet,
        address[] backupaddress,
        uint256 tokenId,
        address tokenAddress,
        string tokenType,
        uint256 tokensAllocated,
        uint256 dateApproved,
        bool claimed,
        uint256 approvalId,
        address claimedWallet
    );

    /**
     * @dev initialize - Initializes the function for Ownable and Reentrancy.
     * @param _directoryContract address of protocol directory contract
     */
    function initialize(address _directoryContract) public initializer {
        __Context_init_unchained();
        __Ownable_init();
        __ReentrancyGuard_init();
        _approvalId = 0;
        directoryContract = _directoryContract;
    }

    /**
     * @notice Function to check if wallet exists in the UID
     * @param _uid string of dApp identifier for a user
     * @param _user address of the user checking exists
     * Fails if not owner uid and user address do not return a wallet
     *
     */
    function checkUIDofSender(string memory _uid, address _user) public view {
        address[] memory wallets = members[_uid].wallets;
        bool walletExists = false;
        for (uint256 i; i < wallets.length; i++) {
            if (wallets[i] == _user) {
                walletExists = true;
            }
        }
        if (walletExists == false) {
            revert OnlyWalletOfUser();
        }
    }

    /**
     * @dev checkIfUIDExists
     * Check if user exists for specific wallet address already internal function
     * @param _walletAddress wallet address of the user
     * @return _exists - A boolean if user exists or not
     *
     */
    function checkIfUIDExists(address _walletAddress)
        public
        view
        returns (bool _exists)
    {
        address IBlacklistUsersAddress = IProtocolDirectory(directoryContract)
            .getBlacklistContract();
        IBlacklist(IBlacklistUsersAddress).checkIfAddressIsBlacklisted(
            _walletAddress
        );
        uint256 _memberLength = allMembers.length;
        for (uint256 i; i < _memberLength; i++) {
            address[] memory _wallets = allMembers[i].wallets;
            if (_wallets.length != 0) {
                uint256 _walletLength = _wallets.length;
                for (uint256 j; j < _walletLength; j++) {
                    if (_wallets[j] == _walletAddress) {
                        _exists = true;
                    }
                }
            }
        }
    }

    /**
     * @notice checkIfWalletHasNFT
     * verify if the user has specific nft 1155 or 721
     * @param _contractAddress address of asset contract
     * @param _NFTType string i.e. ERC721 | ERC1155
     * @param tokenId uint256 tokenId checking for ownership
     * @param userAddress address address to verify ownership of
     * Fails if not owner
     */
    function checkIfWalletHasNFT(
        address _contractAddress,
        string memory _NFTType,
        uint256 tokenId,
        address userAddress
    ) public view {
        // check if wallet has nft
        bool status = false;
        if (
            keccak256(abi.encodePacked((_NFTType))) ==
            keccak256(abi.encodePacked(("ERC721")))
        ) {
            if (IERC721(_contractAddress).ownerOf(tokenId) == userAddress) {
                status = true;
            } else if (
                IERC721Upgradeable(_contractAddress).ownerOf(tokenId) ==
                userAddress
            ) {
                status = true;
            }
        }

        if (
            keccak256(abi.encodePacked((_NFTType))) ==
            keccak256(abi.encodePacked(("ERC1155")))
        ) {
            if (
                IERC1155(_contractAddress).balanceOf(userAddress, tokenId) != 0
            ) {
                status = true;
            } else if (
                IERC1155Upgradeable(_contractAddress).balanceOf(
                    userAddress,
                    tokenId
                ) != 0
            ) {
                status = true;
            }
        }

        if (status == false) {
            revert UserNotTokenOwner();
        }
    }

    /**
     * @dev createMember
     * @param  uid centrally stored id for user
     * @param _walletAddress walletAddress to add wallet and check blacklist
     *
     * Allows to create a member onChain with a unique UID passed.
     * Will revert if the _walletAddress passed in is blacklisted
     *
     */
    function createMember(string memory uid, address _walletAddress) public {
        address IBlacklistUsersAddress = IProtocolDirectory(directoryContract)
            .getBlacklistContract();
        IBlacklist(IBlacklistUsersAddress).checkIfAddressIsBlacklisted(
            _walletAddress
        );
        if (
            (keccak256(abi.encodePacked((members[uid].uid))) !=
                keccak256(abi.encodePacked((uid))) &&
                (checkIfUIDExists(_walletAddress) == false))
        ) {
            if (bytes(uid).length == 0) {
                revert NotValidUID();
            }
            address[] memory _wallets;
            member memory _member = member(
                block.timestamp,
                _wallets,
                _wallets,
                0,
                uid
            );
            members[uid] = _member;
            allMembers.push(_member);
            _addWallet(uid, _walletAddress, true);
            emit memberCreated(_member.uid, _member.dateCreated);
        } else {
            revert UserExists();
        }
    }

    /**
     * @dev getMember
     * @param uid string for centrally located identifier
     * Allows to get member information stored onChain with a unique UID passed.
     * @return member struct for a given uid
     *
     */
    function getMember(string memory uid)
        public
        view
        override
        returns (member memory)
    {
        member memory currentMember = members[uid];
        if (currentMember.dateCreated == 0) {
            revert UserDoesNotExist();
        }
        return currentMember;
    }

    /**
     * @dev getAllMembers
     * Allows to get all member information stored onChain
     * @return allMembers a list of member structs
     *
     */
    function getAllMembers() external view returns (member[] memory) {
        return allMembers;
    }

    /**
     * @dev addWallet - Allows to add Wallet to the user
     * @param uid string for dApp user identifier
     * @param _wallet address wallet being added for given user
     * @param _primary bool whether or not this new wallet is the primary wallet
     *
     *
     */
    function addWallet(
        string memory uid,
        address _wallet,
        bool _primary
    ) public {
        checkUIDofSender(uid, msg.sender);
        _addWallet(uid, _wallet, _primary);
    }

    /**
     * @dev addWallet - Allows to add Wallet to the user
     * @param uid string for dApp user identifier
     * @param _wallet address wallet being added for given user
     * @param _primary bool whether or not this new wallet is the primary wallet
     *
     *
     */
    function _addWallet(
        string memory uid,
        address _wallet,
        bool _primary
    ) internal {
        member storage _member = members[uid];
        _member.wallets.push(_wallet);
        if (_primary) {
            _member.primaryWallet = _member.wallets.length - 1;
        }

        for (uint256 i; i < allMembers.length; i++) {
            member storage member_ = allMembers[i];
            if (
                keccak256(abi.encodePacked((member_.uid))) ==
                keccak256(abi.encodePacked((uid)))
            ) {
                member_.wallets.push(_wallet);
                if (_primary) {
                    member_.primaryWallet = member_.wallets.length - 1;
                }
            }
        }

        emit walletUpdated(
            _member.uid,
            _member.dateCreated,
            _member.backUpWallets,
            _member.wallets,
            _member.primaryWallet
        );
    }

    /**
     * @dev addBackUpWallet - Allows to add backUp Wallets to the user
     * @param uid string for dApp user identifier
     * @param _wallets addresses of wallets being added for given user
     *
     *
     */
    function addBackupWallet(string calldata uid, address[] calldata _wallets)
        public
    {
        checkUIDofSender(uid, msg.sender);
        _addBackupWallet(uid, _wallets, msg.sender);
    }

    /**
     * @dev addBackUpWallet - Allows to add backUp Wallets to the user
     * @param uid string for dApp user identifier
     * @param _wallets addresses of wallets being added for given user
     *
     *
     */
    function _addBackupWallet(
        string calldata uid,
        address[] calldata _wallets,
        address _user
    ) internal {
        if ((checkIfUIDExists(_user) == false)) {
            createMember(uid, _user);
        }
        member storage _member = members[uid];
        if (_member.wallets.length == 0) {
            revert UserMustHaveWallet();
        }
        for (uint256 i; i < _wallets.length; i++) {
            _member.backUpWallets.push(_wallets[i]);
        }

        for (uint256 i; i < allMembers.length; i++) {
            member storage member_ = allMembers[i];
            if (
                keccak256(abi.encodePacked((member_.uid))) ==
                keccak256(abi.encodePacked((uid)))
            ) {
                for (uint256 j; j < _wallets.length; j++) {
                    member_.backUpWallets.push(_wallets[j]);
                }
            }
        }
        emit walletUpdated(
            _member.uid,
            _member.dateCreated,
            _member.backUpWallets,
            _member.wallets,
            _member.primaryWallet
        );
    }

    /**
     * @dev getBackupWallets - Returns backup Wallets for the specific UID
     * @param uid string for dApp user identifier
     *
     */
    function getBackupWallets(string calldata uid)
        external
        view
        returns (address[] memory)
    {
        return members[uid].backUpWallets;
    }

    /**
     * @dev deleteWallet - Allows to delete  wallets of a specific user
     * @param uid string for dApp user identifier
     * @param _walletIndex uint256 which index does the wallet exist in the member wallet list
     *
     */
    function deleteWallet(string calldata uid, uint256 _walletIndex) external {
        checkUIDofSender(uid, msg.sender);
        member storage _member = members[uid];
        delete _member.wallets[_walletIndex];
        address[] storage wallets = _member.wallets;
        for (uint256 i = _walletIndex; i < wallets.length - 1; i++) {
            wallets[i] = wallets[i + 1];
        }

        if (_member.primaryWallet >= _walletIndex) {
            _member.primaryWallet--;
        }
        wallets.pop();

        for (uint256 i; i < allMembers.length; i++) {
            member storage member_ = allMembers[i];
            if (
                keccak256(abi.encodePacked((member_.uid))) ==
                keccak256(abi.encodePacked((uid)))
            ) {
                address[] storage wallets_ = member_.wallets;
                for (uint256 j = _walletIndex; j < wallets_.length - 1; j++) {
                    wallets_[j] = wallets_[j + 1];
                }
                wallets_.pop();
                if (member_.primaryWallet >= _walletIndex) {
                    member_.primaryWallet--;
                }
            }
        }
    }

    /**
     * @dev setPrimaryWallet
     * Allows to set a specific wallet as the primary wallet
     * @param uid string for dApp user identifier
     * @param _walletIndex uint256 which index does the wallet exist in the member wallet list
     *
     */
    function setPrimaryWallet(string calldata uid, uint256 _walletIndex)
        external
        override
    {
        checkUIDofSender(uid, msg.sender);
        members[uid].primaryWallet = _walletIndex;
        for (uint256 i; i < allMembers.length; i++) {
            member storage member_ = allMembers[i];
            if (
                keccak256(abi.encodePacked((member_.uid))) ==
                keccak256(abi.encodePacked((uid)))
            ) {
                member_.primaryWallet = _walletIndex;
            }
        }
    }

    /**
     * @dev getWallets
     * Allows to get all wallets of the user
     * @param uid string for dApp user identifier
     * @return address[] list of wallets
     *
     */
    function getWallets(string calldata uid)
        external
        view
        override
        returns (address[] memory)
    {
        return members[uid].wallets;
    }

    /**
     * @dev getPrimaryWallets
     * Allows to get primary wallet of the user
     * @param uid string for dApp user identifier
     * @return address of the primary wallet per user
     *
     */
    function getPrimaryWallet(string memory uid)
        public
        view
        override
        returns (address)
    {
        return members[uid].wallets[members[uid].primaryWallet];
    }

    /**
     * @dev checkWallet
     * Allows to check if a wallet is a Backup wallets of the user
     * @param _Wallets list of addresses to check if wallet is present
     * @param uid string for dApp user identifier
     * @return boolean if the wallet exists
     *
     */
    function checkWallet(address[] calldata _Wallets, string memory uid)
        internal
        view
        returns (bool)
    {
        address[] memory wallets = members[uid].wallets;
        bool walletExists = false;
        for (uint256 i; i < wallets.length; i++) {
            for (uint256 j = 0; j < _Wallets.length; j++) {
                if (wallets[i] == _Wallets[j]) {
                    walletExists = true;
                }
            }
        }
        return walletExists;
    }

    /**
     * @dev getUID
     * Allows user to pass walletAddress and return UID
     * @param _walletAddress get the UID of the user's if their wallet address is present
     * @return string of the ID used in the dApp to identify they user
     *
     */
    function getUID(address _walletAddress)
        public
        view
        override
        returns (string memory)
    {
        string memory memberuid;
        for (uint256 i; i < allMembers.length; i++) {
            address[] memory _wallets = allMembers[i].wallets;
            if (_wallets.length != 0) {
                for (uint256 j = 0; j < _wallets.length; j++) {
                    if (_wallets[j] == _walletAddress) {
                        memberuid = allMembers[i].uid;
                    }
                }
            }
        }
        if (bytes(memberuid).length == 0) {
            revert UserDoesNotExist();
        }
        return memberuid;
    }

    /**
     * @dev storeBackupAssetsApprovals - Function to store All Types Approvals by the user for backup
     *
     * @param _contractAddress address[] Ordered list of contract addresses for assets
     * @param _tokenIds uint256[] Ordered list of tokenIds associated with contract addresses
     * @param _backUpWallets address[] Ordered list of wallet addresses to backup assets
     * @param _tokenAmount uint256[] Ordered list of amounts per asset contract and token id to protext
     * @param _tokenTypes string[] Ordered list of strings i.e. ERC20 | ERC721 | ERC1155
     * @param _memberUID string for dApp user identifier
     *
     */
    function storeBackupAssetsApprovals(
        address[] calldata _contractAddress,
        uint256[] calldata _tokenIds,
        address[] calldata _backUpWallets,
        uint256[] calldata _tokenAmount,
        string[] calldata _tokenTypes,
        string calldata _memberUID
    ) public {
        if (
            _tokenIds.length != _contractAddress.length ||
            _tokenAmount.length != _tokenTypes.length ||
            _backUpWallets.length != _tokenIds.length
        ) {
            revert TokensDifferentLength();
        }

        if ((checkIfUIDExists(tx.origin) == false)) {
            createMember(_memberUID, tx.origin);
        }

        checkUIDofSender(_memberUID, tx.origin);

        checkUserHasMembership(_memberUID, tx.origin);
        _addBackupWallet(_memberUID, _backUpWallets, tx.origin);
        for (uint256 i; i < _tokenIds.length; i++) {
            address contractAddress = _contractAddress[i];
            string memory tokenType = _tokenTypes[i];
            uint256 tokenId = _tokenIds[i];
            uint256 tokenAllocated = _tokenAmount[i];

            TokenActions.checkAssetContract(
                contractAddress,
                tokenType,
                tokenId,
                tx.origin,
                tokenAllocated
            );

            _storeAssets(
                _memberUID,
                tx.origin,
                _backUpWallets,
                Token(contractAddress, tokenId, tokenAllocated, tokenType)
            );
        }
        IMembership(UserMembershipAddress[_memberUID]).redeemUpdate(_memberUID);
    }

    /**
     * @dev _storeAssets - Internal function to store assets approvals for backup
     * @param uid string identifier of user across dApp
     * @param user address of the user of the dApp
     * @param _backUpWallet address[] list of wallets protected
     * @param _token Token struct containing token information
     *
     */
    function _storeAssets(
        string calldata uid,
        address user,
        address[] calldata _backUpWallet,
        Token memory _token
    ) internal {
        uint256 _dateApproved = block.timestamp;

        BackUpApprovals memory approval = BackUpApprovals(
            _backUpWallet,
            user,
            false,
            ++_approvalId,
            _token,
            _dateApproved,
            uid
        );

        MemberApprovals[uid].push(approval);
        emit BackUpApprovalsEvent(
            uid,
            user,
            _backUpWallet,
            _token.tokenId,
            _token.tokenAddress,
            _token.tokenType,
            _token.tokensAllocated,
            _dateApproved,
            false,
            _approvalId,
            address(0)
        );
    }

    /**
     * @dev executePanic - Public function to transfer assets from one user to another
     * @param _backUpWallet wallet to panic send assets to
     * @param _memberUID uid of the user's assets being moved
     *
     */
    function executePanic(address _backUpWallet, string memory _memberUID)
        external
    {
        checkBackupandSenderofUID(_memberUID, msg.sender);
        address IBlacklistUsersAddress = IProtocolDirectory(directoryContract)
            .getBlacklistContract();
        if (MemberApprovals[_memberUID].length <= 0) {
            revert RequireBackupApproval();
        }
        IBlacklist(IBlacklistUsersAddress).checkIfAddressIsBlacklisted(
            _backUpWallet
        );
        _panic(_memberUID, _backUpWallet);
    }

    /**
     * @dev _checkBackUpExists - Internal function that checks backup approvals if the backup Wallet Exists
     * @param _approvals BackUpApprovals struct with backup information
     * @param _backUpWallet wallet to verify is inside of approval
     *
     */
    function _checkBackUpExists(
        BackUpApprovals memory _approvals,
        address _backUpWallet
    ) internal pure {
        bool backUpExists = false;
        for (uint256 j; j < _approvals.backUpWallet.length; j++) {
            if (_approvals.backUpWallet[j] == _backUpWallet) {
                backUpExists = true;
            }
        }
        if (!backUpExists) {
            revert RequireBackupWallet();
        }
    }

    /**
     * @dev _panic - Private Function to test panic functionality in order to execute and transfer all assets from one user to another
     * @param uid string of identifier for user in dApp
     * @param _backUpWallet address where to send assets to
     *
     */
    function _panic(string memory uid, address _backUpWallet) internal {
        BackUpApprovals[] storage _approvals = MemberApprovals[uid];
        for (uint256 i; i < _approvals.length; i++) {
            BackUpApprovals storage _userApproval = _approvals[i];
            if (_userApproval.claimed == false) {
                _checkBackUpExists(_userApproval, _backUpWallet);
                if (
                    keccak256(
                        abi.encodePacked((_userApproval.token.tokenType))
                    ) == keccak256(abi.encodePacked(("ERC20")))
                ) {
                    IERC20 ERC20 = IERC20(_userApproval.token.tokenAddress);

                    uint256 tokenAllowance = ERC20.allowance(
                        _userApproval.approvedWallet,
                        address(this)
                    );
                    uint256 tokenBalance = ERC20.balanceOf(
                        _userApproval.approvedWallet
                    );

                    if (tokenBalance <= tokenAllowance) {
                        ERC20.transferFrom(
                            _userApproval.approvedWallet,
                            _backUpWallet,
                            tokenBalance
                        );
                    } else {
                        ERC20.transferFrom(
                            _userApproval.approvedWallet,
                            _backUpWallet,
                            tokenAllowance
                        );
                    }

                    _userApproval.claimed = true;
                    emit BackUpApprovalsEvent(
                        _userApproval._uid,
                        _userApproval.approvedWallet,
                        _userApproval.backUpWallet,
                        _userApproval.token.tokenId,
                        _userApproval.token.tokenAddress,
                        _userApproval.token.tokenType,
                        _userApproval.token.tokensAllocated,
                        _userApproval.dateApproved,
                        _userApproval.claimed,
                        _userApproval.approvalId,
                        _backUpWallet
                    );
                }
                if (
                    keccak256(
                        abi.encodePacked((_userApproval.token.tokenType))
                    ) == keccak256(abi.encodePacked(("ERC721")))
                ) {
                    IERC721 ERC721 = IERC721(_userApproval.token.tokenAddress);

                    address _tokenAddress = ERC721.ownerOf(
                        _userApproval.token.tokenId
                    );

                    if (_tokenAddress == _userApproval.approvedWallet) {
                        ERC721.safeTransferFrom(
                            _userApproval.approvedWallet,
                            _backUpWallet,
                            _userApproval.token.tokenId
                        );
                    }

                    _userApproval.claimed = true;
                    emit BackUpApprovalsEvent(
                        _userApproval._uid,
                        _userApproval.approvedWallet,
                        _userApproval.backUpWallet,
                        _userApproval.token.tokenId,
                        _userApproval.token.tokenAddress,
                        _userApproval.token.tokenType,
                        _userApproval.token.tokensAllocated,
                        _userApproval.dateApproved,
                        _userApproval.claimed,
                        _userApproval.approvalId,
                        _backUpWallet
                    );
                }
                if (
                    keccak256(
                        abi.encodePacked((_userApproval.token.tokenType))
                    ) == keccak256(abi.encodePacked(("ERC1155")))
                ) {
                    IERC1155 ERC1155 = IERC1155(
                        _userApproval.token.tokenAddress
                    );

                    uint256 _balance = ERC1155.balanceOf(
                        _userApproval.approvedWallet,
                        _userApproval.token.tokenId
                    );
                    bytes memory data;

                    if (_balance < _userApproval.token.tokensAllocated) {
                        ERC1155.safeTransferFrom(
                            _userApproval.approvedWallet,
                            _backUpWallet,
                            _userApproval.token.tokenId,
                            _balance,
                            data
                        );
                    } else {
                        ERC1155.safeTransferFrom(
                            _userApproval.approvedWallet,
                            _backUpWallet,
                            _userApproval.token.tokenId,
                            _userApproval.token.tokensAllocated,
                            data
                        );
                    }

                    _userApproval.claimed = true;
                    emit BackUpApprovalsEvent(
                        _userApproval._uid,
                        _userApproval.approvedWallet,
                        _userApproval.backUpWallet,
                        _userApproval.token.tokenId,
                        _userApproval.token.tokenAddress,
                        _userApproval.token.tokenType,
                        _userApproval.token.tokensAllocated,
                        _userApproval.dateApproved,
                        _userApproval.claimed,
                        _userApproval.approvalId,
                        _backUpWallet
                    );
                }
            }
        }
    }

    /**
     * @dev getBackupApprovals - function to return all backupapprovals for a specific UID
     * @param uid string of identifier for user in dApp
     * @return BackUpApprovals[] list of BackUpApprovals struct
     *
     */
    function getBackupApprovals(string memory uid)
        external
        view
        returns (BackUpApprovals[] memory)
    {
        return MemberApprovals[uid];
    }

    /**
     * @dev editBackup - Function to edit individual backup approvals
     * @param approvalId_ uint256 id to lookup Approval and edit
     * @param _contractAddress address contractAddress of asset to save
     * @param _tokenIds uint256 tokenId of asset
     * @param _tokenAmount uint256 amount of specific token
     * @param _tokenType string type of the token i.e. ERC20 | ERC721 | ERC1155
     * @param _uid string of identifier for user in dApp
     *
     */
    function editBackUp(
        uint256 approvalId_,
        address _contractAddress,
        uint256 _tokenIds,
        uint256 _tokenAmount,
        string calldata _tokenType,
        string memory _uid
    ) external {
        member memory _member = getMember(_uid);
        checkUIDofSender(_uid, msg.sender);
        checkUserHasMembership(_uid, msg.sender);

        BackUpApprovals[] storage _approvals = MemberApprovals[_member.uid];
        for (uint256 i = 0; i < _approvals.length; i++) {
            BackUpApprovals storage _userApprovals = _approvals[i];
            if (_userApprovals.approvalId == approvalId_) {
                _userApprovals.token.tokenAddress = _contractAddress;
                _userApprovals.token.tokenId = _tokenIds;
                _userApprovals.token.tokensAllocated = _tokenAmount;
                _userApprovals.token.tokenType = _tokenType;
            }
        }
        IMembership(UserMembershipAddress[_uid]).redeemUpdate(_uid);
    }

    /**
     * @dev editAllBackUp - Function to delete and add new approvals for backup
     * @param _contractAddress address[] Ordered list of addresses for asset contracts
     * @param _tokenIds uint256[] Ordered list of tokenIds to backup
     * @param _backUpWallets address[] Ordered list of wallets that can be backups
     * @param _tokenAmount uint256[] Ordered list of amounts of tokens to backup
     * @param _tokenTypes string[] Ordered list of string tokenTypes i.e. ERC20 | ERC721 | ERC1155
     * @param _memberUID string of identifier for user in dApp
     *
     *
     */
    function editAllBackUp(
        address[] calldata _contractAddress,
        uint256[] calldata _tokenIds,
        address[] calldata _backUpWallets,
        uint256[] calldata _tokenAmount,
        string[] calldata _tokenTypes,
        string calldata _memberUID
    ) external {
        checkUIDofSender(_memberUID, msg.sender);
        checkUserHasMembership(_memberUID, tx.origin);
        deleteAllBackUp(_memberUID);

        storeBackupAssetsApprovals(
            _contractAddress,
            _tokenIds,
            _backUpWallets,
            _tokenAmount,
            _tokenTypes,
            _memberUID
        );
    }

    /**
     * @dev deleteAllBackUp - Function to delete all backup approvals
     * @param _uid string of identifier for user in dApp
     *
     */
    function deleteAllBackUp(string memory _uid) public {
        checkUIDofSender(_uid, tx.origin);
        member memory _member = getMember(_uid);
        delete MemberApprovals[_member.uid];
    }

    /**
     * @notice checkUserHasMembership - Function to check if user has membership
     * @param _uid string of identifier for user in dApp
     * @param _user address of the user of the dApp
     *
     */
    function checkUserHasMembership(string memory _uid, address _user)
        public
        view
    {
        IBlacklist(IProtocolDirectory(directoryContract).getBlacklistContract())
            .checkIfAddressIsBlacklisted(_user);
        IMembership _membership = IMembership(UserMembershipAddress[_uid]);
        bool _MembershipActive = _membership.checkIfMembershipActive(_uid);
        if (_MembershipActive == false) {
            revert MembershipNotActive();
        } else {
            MembershipStruct memory Membership = IMembership(
                UserMembershipAddress[_uid]
            ).getMembership(_uid);
            if (Membership.updatesPerYear <= 0) {
                revert MembershipRequireTopup();
            }
        }
    }

    /**
     * @dev Function set MembershipAddress for a Uid
     * @param _uid string of identifier for user in dApp
     * @param _Membership address of the user's associated membership contract
     *
     */
    function setIMembershipAddress(string memory _uid, address _Membership)
        external
    {
        address factoryAddress = IProtocolDirectory(directoryContract)
            .getMembershipFactory();
        if (factoryAddress != msg.sender) {
            revert NotFactoryAddress();
        }
        UserMembershipAddress[_uid] = _Membership;
    }

    /**
     * @dev Function to get MembershipAddress for a given Uid
     * @param _uid string of identifier for user in dApp
     *
     */
    function getIMembershipAddress(string memory _uid)
        external
        view
        returns (address)
    {
        return UserMembershipAddress[_uid];
    }

    /**
     * @notice Function to check if backup wallet exists in the UID
     * @param _uid string of dApp identifier for a user
     * @param _backup address of the wallet checking exists
     * Fails if not owner uid and backup address do not return a wallet
     *
     */
    function checkBackupandSenderofUID(string memory _uid, address _backup)
        public
        view
    {
        address[] memory wallets = members[_uid].wallets;
        bool walletExists = false;
        for (uint256 i; i < wallets.length; i++) {
            if (wallets[i] == _backup) {
                walletExists = true;
            }
        }
        address[] memory backupwallets = members[_uid].backUpWallets;
        for (uint256 i; i < backupwallets.length; i++) {
            if (backupwallets[i] == _backup) {
                walletExists = true;
            }
        }

        if (walletExists == false) {
            revert UserDoesNotExist();
        }
    }
}