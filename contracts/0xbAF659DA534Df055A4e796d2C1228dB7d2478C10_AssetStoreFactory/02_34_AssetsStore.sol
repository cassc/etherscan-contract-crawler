//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./libraries/TokenActions.sol";
import "./interfaces/IProtocolDirectory.sol";
import "./interfaces/IMember.sol";
import "./interfaces/IBlacklist.sol";
import "./interfaces/IMembership.sol";
import "./interfaces/IAssetStore.sol";
import "./interfaces/IAssetStoreFactory.sol";
import "./structs/MemberStruct.sol";
import "./structs/TokenStruct.sol";
import "./structs/ApprovalsStruct.sol";

// Errors Definition
error OnlyRelayer(); //  "Only relayer contract can call this"
error DifferentLengthOfArrays(); // "Lengths of parameters need to be equal"
error InvalidTokenRange(); // "tokenAmount can only range from 0-100 percentage"
error OnlyBeneficiary(); // "Only the designated beneficiary can claim assets"
error NoApprovalExists(); // "No Approvals found"
error NotCharity(); // "is not charity"
error InsufficientTopups(); // "User does not have sufficient topUp Updates in order to store approvals"
error NoMembershipExists(); // "User does not have a membership contract deployed"
error StoringBackupFailed(); // "Storing Backup Failed"

/**
 * @title AssetsStore
 * @notice This contract is deployed by the AssetsStoreFactory.sol
 * and is the contract that holds the approvals for a user's directives
 *
 * @dev The ownership of this contract is held by the deployer factory
 *
 */

contract AssetsStore is IAssetStore, Initializable, OwnableUpgradeable {
    // Returns token Approvals for specific UID
    mapping(string => Approvals[]) private MemberApprovals;

    // Mapping Beneficiaries to a specific Approval for Claiming
    mapping(address => Approvals[]) private BeneficiaryClaimableAsset;

    // Storing ApprovalId for different approvals stored
    uint88 private _approvalId;

    // address for the protocol directory contract
    address private directoryContract;

    address private IMembershipAddress;

    /**
     * @notice Event used for querying approvals stored
     * by this contract
     *
     * @param uid string of the central identifier within the dApp
     * @param approvedWallet address for original holder of the asset
     * @param beneficiaryName string associated with beneficiaryAddress wallet
     * @param beneficiaryAddress address for the wallet receiving the assets
     * @param tokenId uint256 of the ID of the token being transferred
     * @param tokenAddress address for the contract of the asset
     * @param tokenType string representing what ERC the token is
     * @param tokensAllocated uint256 representing the % allocation of an asset
     * @param dateApproved uint256 for the block number when the approval is acted on
     * @param claimed bool for showing if the approval has been claimed by a beneficiary
     * @param active bool for if the claiming period is currently active
     * @param approvalId uint256 representing which approval the event is tied to
     * @param claimExpiryTime uint256 of a block number when claiming can no longer happen
     * @param approvedTokenAmount uint256 representing the magnitude of tokens to be transferred
     * at the time of claiming.
     *
     */
    event ApprovalsEvent(
        string uid,
        string beneficiaryName,
        uint256 tokenId,
        string tokenType,
        uint256 tokensAllocated,
        uint256 dateApproved,
        uint256 approvalId,
        uint256 claimExpiryTime,
        uint256 approvedTokenAmount,
        address approvedWallet,
        address beneficiaryAddress,
        address tokenAddress,
        bool claimed,
        bool active
    );

    /**
     * @dev Modifier checking that only the RelayerContract can invoke certain functions
     *
     */
    modifier onlyRelayerContract() {
        address relayerAddress = IProtocolDirectory(directoryContract)
            .getRelayerContract();
        if (msg.sender != relayerAddress) {
            revert OnlyRelayer();
        }
        _;
    }

    /**
     * @dev initialize - Initializes the function for Ownable and Reentrancy.
     * @param _directoryContract address of the ProtocolDirectory Contract
     * @param _membershipAddress address of the Contract deployed for this
     * user's membership
     */
    function initialize(address _directoryContract, address _membershipAddress)
        public
        initializer
    {
        directoryContract = _directoryContract;
        IMembershipAddress = _membershipAddress;
        _approvalId = 0;
    }

    /**
     * @notice Function to store All Types of Approvals and Backups by the user in one function
     * @dev storeAssetsAndBackUpApprovals calls
     *  storeBackupAssetsApprovals & storeAssetsApprovals
     * 
     * sent to storeAssetsApprovals:
     * @param _contractAddress address[] Ordered list of contracts for different assets
     * @param _beneficiaries address[] Ordered list of addresses associated with addresses/wallets assets will be claimed by
     * @param _beneficiaryNames string[] Ordered list of names associated with the _beneficiaries
     * @param _beneficiaryIsCharity bool[] Ordered list of booleans representing if the beneficiary is charity, an EOA not able to claim assets independently
     * @param _tokenTypes string[] Ordered list of strings for the token types (i.e. ERC20, ERC1155, ERC721)
     * @param _tokenIds uint256[] Ordered list of tokenIds for the listed contractAddresses
     * @param _tokenAmount uint256[] Ordered list of numbers represnting the %'s of assets to go to a beneficiary
     
     * sent to storeBackupAssetsApprovals:
     * @param _backUpTokenIds uint256[] Ordered list of tokenIds to be in a backup plan
     * @param _backupTokenAmount uint256[] Ordered list representing a magnitube of tokens to be in a backupPlan
     * @param _backUpWallets address[] Ordered list of destination wallets for the backupPlan
     * @param _backUpAddresses address[] Ordered list of contract addresses of assets for the backupPlan
     * @param _backupTokenTypes string[] Ordered list of strings for the token types (i.e. ERC20, ERC1155, ERC721)
     * @param uid string of the dApp identifier for the user
     * 
     * 
     */
    function storeAssetsAndBackUpApprovals(
        address[] calldata _contractAddress,
        address[] calldata _beneficiaries,
        string[] memory _beneficiaryNames,
        bool[] memory _beneficiaryIsCharity,
        string[] memory _tokenTypes,
        uint256[] memory _tokenIds,
        uint256[] memory _tokenAmount,
        uint256[] memory _backUpTokenIds,
        uint256[] memory _backupTokenAmount,
        address[] calldata _backUpWallets,
        address[] calldata _backUpAddresses,
        string[] memory _backupTokenTypes,
        string memory uid
    ) external {
        address IMemberAddress = IProtocolDirectory(directoryContract)
            .getMemberContract();
        if ((IMember(IMemberAddress).checkIfUIDExists(msg.sender) == false)) {
            IMember(IMemberAddress).createMember(uid, msg.sender);
        }
        checkUserHasMembership(uid);
        IMember(IMemberAddress).checkUIDofSender(uid, msg.sender);

        IMember(IMemberAddress).storeBackupAssetsApprovals(
            _backUpAddresses,
            _backUpTokenIds,
            _backUpWallets,
            _backupTokenAmount,
            _backupTokenTypes,
            uid
        );
        storeAssetsApprovals(
            _contractAddress,
            _tokenIds,
            _beneficiaries,
            _beneficiaryNames,
            _beneficiaryIsCharity,
            _tokenAmount,
            _tokenTypes,
            uid
        );
    }

    /**
     * @notice storeAssetsApprovals - Function to store All Types Approvals by the user
     * @dev All of the arrays passed in need to be IN ORDER
     * they will be accessed in a loop together
     * @param _contractAddress address[] Ordered list of contracts for different assets
     * @param _tokenIds uint256[] Ordered list of tokenIds for the listed contractAddresses
     * @param _beneficiaries address[] Ordered list of addresses associated with addresses/wallets assets will be claimed by
     * @param _beneficiaryNames string[] Ordered list of names associated with the _beneficiaries
     * @param _beneficiaryIsCharity bool[] Ordered list of booleans representing if the beneficiary is charity, an EOA not able to claim assets independently
     * @param _tokenAmount uint256[] Ordered list of numbers represnting the %'s of assets to go to a beneficiary
     * @param _tokenTypes string[] Ordered list of strings for the token types (i.e. ERC20, ERC1155, ERC721)
     * @param _memberUID string of the dApp identifier for the user
     *
     */
    function storeAssetsApprovals(
        address[] calldata _contractAddress,
        uint256[] memory _tokenIds,
        address[] calldata _beneficiaries,
        string[] memory _beneficiaryNames,
        bool[] memory _beneficiaryIsCharity,
        uint256[] memory _tokenAmount,
        string[] memory _tokenTypes,
        string memory _memberUID
    ) public {
        if (
            _tokenIds.length != _contractAddress.length ||
            _beneficiaryNames.length != _beneficiaries.length ||
            _tokenAmount.length != _tokenTypes.length ||
            _beneficiaryIsCharity.length != _tokenIds.length
        ) {
            revert DifferentLengthOfArrays();
        }

        address IMemberAddress = IProtocolDirectory(directoryContract)
            .getMemberContract();
        if ((IMember(IMemberAddress).checkIfUIDExists(msg.sender) == false)) {
            IMember(IMemberAddress).createMember(_memberUID, msg.sender);
        }
        IMember(IMemberAddress).checkUIDofSender(_memberUID, msg.sender);
        checkUserHasMembership(_memberUID);

        uint256 _approvalLength = _tokenIds.length;

        for (uint256 i; i < _approvalLength; i++) {
            address contractAddress = _contractAddress[i];
            bool isCharity = _beneficiaryIsCharity[i];
            address beneficiary_ = _beneficiaries[i];
            string memory beneficiaryName_ = _beneficiaryNames[i];
            string memory tokenType = _tokenTypes[i];
            uint256 tokenAmount = _tokenAmount[i];
            uint256 tokenId_ = _tokenIds[i];
            uint256 _dateApproved = block.timestamp;

            TokenActions.checkAssetContract(
                contractAddress,
                tokenType,
                tokenId_,
                msg.sender,
                tokenAmount
            );
            if (tokenAmount > 100 || tokenAmount < 0) {
                revert InvalidTokenRange();
            }

            Approvals memory approval = Approvals(
                Beneficiary(beneficiary_, isCharity, beneficiaryName_),
                Token(contractAddress, tokenId_, tokenAmount, tokenType),
                _dateApproved,
                msg.sender,
                false,
                false,
                ++_approvalId,
                0,
                0,
                _memberUID
            );

            BeneficiaryClaimableAsset[beneficiary_].push(approval);
            MemberApprovals[_memberUID].push(approval);

            emit ApprovalsEvent(
                _memberUID,
                beneficiaryName_,
                tokenId_,
                tokenType,
                tokenAmount,
                _dateApproved,
                _approvalId,
                0,
                0,
                msg.sender,
                beneficiary_,
                contractAddress,
                false,
                false
            );
        }
        IMembership(IMembershipAddress).redeemUpdate(_memberUID);
    }

    /**
     * @notice getApproval - Function to get a specific token Approval for the user passing in UID and ApprovalID
     * @dev searches state for a match by uid and approvalId for a given user
     *
     * @param uid string of the dApp identifier for the user
     * @param approvalId number of the individual approval to lookup
     *
     * @return approval_ struct storing information for an Approval
     */
    function getApproval(string memory uid, uint256 approvalId)
        external
        view
        returns (Approvals memory approval_)
    {
        Approvals[] memory _approvals = MemberApprovals[uid];
        for (uint256 i = 0; i < _approvals.length; i++) {
            if (_approvals[i].approvalId == approvalId) {
                approval_ = _approvals[i];
            }
        }
    }

    /**
     * @notice getBeneficiaryApproval - Function to get a token Approval for the beneficiaries - Admin function
     * @param _benAddress address to lookup a specific list of approvals for given beneficiary address
     * @return approval_ a list of approval structs for a specific address
     */
    function getBeneficiaryApproval(address _benAddress)
        external
        view
        returns (Approvals[] memory approval_)
    {
        approval_ = BeneficiaryClaimableAsset[_benAddress];
    }

    /**
     * @notice getApprovals - Function to get all token Approvals for the user
     * @param uid string of the dApp identifier for the user
     * @return Approvals[] a list of all the approval structs associated with a user
     */
    function getApprovals(string memory uid)
        external
        view
        returns (Approvals[] memory)
    {
        return MemberApprovals[uid];
    }

    /**
     * @notice setApprovalClaimed - Function to set approval claimed for a specific apprival id
     * @param uid string of the dApp identifier for the user
     * @param _id uint256 the id of the approval claimed
     *
     * emits an event to indicate state change of an approval as well
     * as changing the state inside of the MemberApprovals list
     */
    function setApprovalClaimed(string memory uid, uint256 _id) internal {
        Approvals[] storage _approvals = MemberApprovals[uid];
        for (uint256 i = 0; i < _approvals.length; i++) {
            if (_approvals[i].approvalId == _id) {
                Approvals storage _userApproval = _approvals[i];
                _userApproval.claimed = true;
                _userApproval.active = false;
                emit ApprovalsEvent(
                    _userApproval._uid,
                    _userApproval.beneficiary.beneficiaryName,
                    _userApproval.token.tokenId,
                    _userApproval.token.tokenType,
                    _userApproval.token.tokensAllocated,
                    _userApproval.dateApproved,
                    _userApproval.approvalId,
                    _userApproval.claimExpiryTime,
                    _userApproval.approvedTokenAmount,
                    _userApproval.approvedWallet,
                    _userApproval.beneficiary.beneficiaryAddress,
                    _userApproval.token.tokenAddress,
                    _userApproval.claimed,
                    _userApproval.active
                );
            }
        }
    }

    /**
     * @dev setBenApprovalClaimed - Function to set approval claimed for a specific apprival id for ben
     * @param _user address of the dApp identifier for the user
     * @param _id uint256 the id of the approval claimed
     *
     * emits an event to indicate state change of an approval as well
     * as changing the state inside of the BeneficiaryClaimableAsset list
     */
    function setBenApprovalClaimed(address _user, uint256 _id) internal {
        Approvals[] storage _approvals = BeneficiaryClaimableAsset[_user];
        for (uint256 i = 0; i < _approvals.length; i++) {
            if (_approvals[i].approvalId == _id) {
                Approvals storage userApproval = _approvals[i];
                userApproval.claimed = true;
                userApproval.active = false;
                emit ApprovalsEvent(
                    userApproval._uid,
                    userApproval.beneficiary.beneficiaryName,
                    userApproval.token.tokenId,
                    userApproval.token.tokenType,
                    userApproval.token.tokensAllocated,
                    userApproval.dateApproved,
                    userApproval.approvalId,
                    userApproval.claimExpiryTime,
                    userApproval.approvedTokenAmount,
                    userApproval.approvedWallet,
                    userApproval.beneficiary.beneficiaryAddress,
                    userApproval.token.tokenAddress,
                    userApproval.claimed,
                    userApproval.active
                );
            }
        }
    }

    /**
     * @notice transferUnclaimedAsset - Function to claim Unclaimed Assets passed the claimable expiry time
     * @param uid string of the dApp identifier for the user
     */
    function transferUnclaimedAssets(string memory uid)
        external
        onlyRelayerContract
    {
        address TransferPool = IProtocolDirectory(directoryContract)
            .getTransferPool();
        Approvals[] storage _approval = MemberApprovals[uid];
        for (uint256 i = 0; i < _approval.length; i++) {
            if (
                block.timestamp >= _approval[i].claimExpiryTime &&
                _approval[i].active == true &&
                _approval[i].claimed == false
            ) {
                if (
                    keccak256(
                        abi.encodePacked((_approval[i].token.tokenType))
                    ) == keccak256(abi.encodePacked(("ERC20")))
                ) {
                    IERC20 ERC20 = IERC20(_approval[i].token.tokenAddress);

                    // Percentage approach for storing erc20
                    uint256 _tokenAmount = (_approval[i].token.tokensAllocated *
                        ERC20.balanceOf(_approval[i].approvedWallet)) / 100;

                    ERC20.transferFrom(
                        _approval[i].approvedWallet,
                        TransferPool,
                        _tokenAmount
                    );

                    setApprovalClaimed(uid, _approval[i].approvalId);
                    setBenApprovalClaimed(
                        _approval[i].beneficiary.beneficiaryAddress,
                        _approval[i].approvalId
                    );
                }

                // transfer erc721
                if (
                    keccak256(
                        abi.encodePacked((_approval[i].token.tokenType))
                    ) == keccak256(abi.encodePacked(("ERC721")))
                ) {
                    IERC721 ERC721 = IERC721(_approval[i].token.tokenAddress);

                    ERC721.safeTransferFrom(
                        _approval[i].approvedWallet,
                        TransferPool,
                        _approval[i].token.tokenId
                    );
                    setApprovalClaimed(uid, _approval[i].approvalId);
                    setBenApprovalClaimed(
                        _approval[i].beneficiary.beneficiaryAddress,
                        _approval[i].approvalId
                    );
                }

                // transfer erc1155
                if (
                    keccak256(
                        abi.encodePacked((_approval[i].token.tokenType))
                    ) == keccak256(abi.encodePacked(("ERC1155")))
                ) {
                    IERC1155 ERC1155 = IERC1155(
                        _approval[i].token.tokenAddress
                    );
                    uint256 _tokenAmount = (_approval[i].token.tokensAllocated *
                        ERC1155.balanceOf(
                            _approval[i].approvedWallet,
                            _approval[i].token.tokenId
                        )) / 100;

                    bytes memory data;
                    ERC1155.safeTransferFrom(
                        _approval[i].approvedWallet,
                        TransferPool,
                        _approval[i].token.tokenId,
                        _tokenAmount,
                        data
                    );

                    setApprovalClaimed(uid, _approval[i].approvalId);
                    setBenApprovalClaimed(
                        _approval[i].beneficiary.beneficiaryAddress,
                        _approval[i].approvalId
                    );
                }
            }
        }
    }

    /**
     * @dev claimAsset - Function to claim Asset from a specific UID
     * @param uid string of the dApp identifier for the user
     * @param approvalId_ uint256 id of the specific approval being claimed
     *
     */
    function claimAsset(string memory uid, uint256 approvalId_) external {
        address IBlacklistUsersAddress = IProtocolDirectory(directoryContract)
            .getBlacklistContract();
        IBlacklist(IBlacklistUsersAddress).checkIfAddressIsBlacklisted(
            msg.sender
        );
        Approvals[] storage _approval = BeneficiaryClaimableAsset[msg.sender];
        for (uint256 i = 0; i < _approval.length; i++) {
            Approvals memory _userApproval = _approval[i];
            if (
                keccak256(abi.encodePacked((_userApproval._uid))) ==
                keccak256(abi.encodePacked((uid)))
            ) {
                if (
                    _userApproval.beneficiary.beneficiaryAddress != msg.sender
                ) {
                    revert OnlyBeneficiary();
                }
                if (
                    _userApproval.active == true &&
                    _userApproval.claimed == false
                ) {
                    if (_userApproval.approvalId == approvalId_) {
                        // transfer erc20
                        if (
                            keccak256(
                                abi.encodePacked(
                                    (_userApproval.token.tokenType)
                                )
                            ) == keccak256(abi.encodePacked(("ERC20")))
                        ) {
                            setApprovalClaimed(uid, _userApproval.approvalId);
                            bool success = TokenActions.sendERC20(
                                _userApproval
                            );
                            if (success) {
                                _userApproval.claimed = true;
                            }
                        }

                        // transfer erc721
                        if (
                            keccak256(
                                abi.encodePacked(
                                    (_userApproval.token.tokenType)
                                )
                            ) == keccak256(abi.encodePacked(("ERC721")))
                        ) {
                            IERC721 ERC721 = IERC721(
                                _userApproval.token.tokenAddress
                            );

                            _userApproval.claimed = true;
                            setApprovalClaimed(uid, _userApproval.approvalId);
                            ERC721.safeTransferFrom(
                                _userApproval.approvedWallet,
                                _userApproval.beneficiary.beneficiaryAddress,
                                _userApproval.token.tokenId
                            );
                        }

                        // transfer erc1155
                        if (
                            keccak256(
                                abi.encodePacked(
                                    (_userApproval.token.tokenType)
                                )
                            ) == keccak256(abi.encodePacked(("ERC1155")))
                        ) {
                            IERC1155 ERC1155 = IERC1155(
                                _userApproval.token.tokenAddress
                            );
                            uint256 _tokenAmount = (
                                _userApproval.approvedTokenAmount
                            );

                            bytes memory data;
                            _userApproval.claimed = true;
                            setApprovalClaimed(uid, _userApproval.approvalId);
                            ERC1155.safeTransferFrom(
                                _userApproval.approvedWallet,
                                _userApproval.beneficiary.beneficiaryAddress,
                                _userApproval.token.tokenId,
                                _tokenAmount,
                                data
                            );
                        }

                        break;
                    }
                }
            }
        }
    }

    /**
     * @dev sendAssetsToCharity
     * @param _charityBeneficiaryAddress address of the charity beneficiary
     * @param _uid the uid stored for the user
     *
     * Send assets to the charity beneficiary if they exist;
     *
     */
    function sendAssetsToCharity(
        address _charityBeneficiaryAddress,
        string calldata _uid
    ) external onlyRelayerContract {
        // look to see if this address is a charity
        Approvals[]
            storage charityBeneficiaryApprovals = BeneficiaryClaimableAsset[
                _charityBeneficiaryAddress
            ];
        if (charityBeneficiaryApprovals.length == 0) {
            revert NoApprovalExists();
        }
        for (uint256 i; i < charityBeneficiaryApprovals.length; i++) {
            Approvals memory _beneficiaryApproval = charityBeneficiaryApprovals[
                i
            ];
            if (!_beneficiaryApproval.beneficiary.isCharity) {
                revert NotCharity();
            }
            if (
                _beneficiaryApproval.active == true &&
                _beneficiaryApproval.claimed == false &&
                (keccak256(
                    abi.encodePacked((_beneficiaryApproval.token.tokenType))
                ) == keccak256(abi.encodePacked(("ERC20"))))
            ) {
                setApprovalClaimed(_uid, _beneficiaryApproval.approvalId);
                setBenApprovalClaimed(
                    _charityBeneficiaryAddress,
                    _beneficiaryApproval.approvalId
                );
                bool success = TokenActions.sendERC20(_beneficiaryApproval);
                if (success) {
                    _beneficiaryApproval.claimed = true;
                }
            }
        }
    }

    /**
     * @dev getClaimableAssets allows users to get all claimable assets for a specific user.
     * @return return a list of assets being protected by this contract
     */
    function getClaimableAssets() external view returns (Token[] memory) {
        Approvals[] memory _approval = BeneficiaryClaimableAsset[msg.sender];
        uint256 _tokensCount = 0;
        uint256 _index = 0;

        for (uint256 k = 0; k < _approval.length; k++) {
            if (_approval[k].claimed == false && _approval[k].active == true) {
                _tokensCount++;
            }
        }
        Token[] memory _tokens = new Token[](_tokensCount);
        for (uint256 i = 0; i < _approval.length; i++) {
            if (_approval[i].claimed == false && _approval[i].active == true) {
                _tokens[_index] = _approval[i].token;
                _index++;
            }
        }
        return _tokens;
    }

    /**
     *  @notice setApprovalActive called by external actor to mark claiming period
     *  is active and ready
     *  @param uid string of the dApp identifier for the user
     *
     */
    function setApprovalActive(string memory uid) external onlyRelayerContract {
        Approvals[] storage _approvals = MemberApprovals[uid];
        for (uint256 i = 0; i < _approvals.length; i++) {
            _approvals[i].active = true;
            _approvals[i].claimExpiryTime = block.timestamp + 31536000;
            Approvals[] storage approvals = BeneficiaryClaimableAsset[
                _approvals[i].beneficiary.beneficiaryAddress
            ];
            for (uint256 j = 0; j < approvals.length; j++) {
                if (
                    keccak256(abi.encodePacked((approvals[j]._uid))) ==
                    keccak256(abi.encodePacked((uid)))
                ) {
                    Approvals storage _userApprovals = approvals[j];
                    /// @notice check if is ERC20 for preAllocating then claiming
                    if (
                        keccak256(
                            abi.encodePacked((_userApprovals.token.tokenType))
                        ) == keccak256(abi.encodePacked(("ERC20")))
                    ) {
                        /// @notice setting fixed tokenAmount to claim later
                        _userApprovals.approvedTokenAmount =
                            (_userApprovals.token.tokensAllocated *
                                IERC20(_userApprovals.token.tokenAddress)
                                    .balanceOf(_userApprovals.approvedWallet)) /
                            100;
                    }

                    if (
                        keccak256(
                            abi.encodePacked((_userApprovals.token.tokenType))
                        ) == keccak256(abi.encodePacked(("ERC1155")))
                    ) {
                        _userApprovals.approvedTokenAmount =
                            (_userApprovals.token.tokensAllocated *
                                IERC1155(_userApprovals.token.tokenAddress)
                                    .balanceOf(
                                        _userApprovals.approvedWallet,
                                        _userApprovals.token.tokenId
                                    )) /
                            100;
                    }

                    _userApprovals.active = true;
                    _userApprovals.claimExpiryTime = block.timestamp + 31536000;

                    emit ApprovalsEvent(
                        _userApprovals._uid,
                        _userApprovals.beneficiary.beneficiaryName,
                        _userApprovals.token.tokenId,
                        _userApprovals.token.tokenType,
                        _userApprovals.token.tokensAllocated,
                        _userApprovals.dateApproved,
                        _userApprovals.approvalId,
                        _userApprovals.claimExpiryTime,
                        _userApprovals.approvedTokenAmount,
                        _userApprovals.approvedWallet,
                        _userApprovals.beneficiary.beneficiaryAddress,
                        _userApprovals.token.tokenAddress,
                        _userApprovals.claimed,
                        _userApprovals.active
                    );
                }
            }
        }
    }

    /**
     * @dev deleteApprooval - Deletes the approval of the specific UID
     * @param uid string of the dApp identifier for the user
     * @param approvalId uint256 id of the approval struct to be deleted
     *
     */
    function deleteApproval(string calldata uid, uint256 approvalId) external {
        Approvals[] storage approval_ = MemberApprovals[uid];
        IMember(IProtocolDirectory(directoryContract).getMemberContract())
            .checkUIDofSender(uid, msg.sender);
        for (uint256 i; i < approval_.length; i++) {
            Approvals storage _userApproval = approval_[i];
            if (_userApproval.approvalId == approvalId) {
                Approvals[] storage _approval_ = MemberApprovals[uid];
                for (uint256 j = i; j < _approval_.length - 1; j++) {
                    _approval_[j] = _approval_[j + 1];
                }
                _approval_.pop();
                approval_ = _approval_;

                Approvals[] storage _benApproval = BeneficiaryClaimableAsset[
                    _userApproval.beneficiary.beneficiaryAddress
                ];
                for (uint256 k; k < _benApproval.length; k++) {
                    if (_benApproval[k].approvalId == approvalId) {
                        Approvals[]
                            storage _benapproval_ = BeneficiaryClaimableAsset[
                                _benApproval[k].beneficiary.beneficiaryAddress
                            ];
                        for (uint256 l = k; l < _benapproval_.length - 1; l++) {
                            _benapproval_[l] = _benapproval_[l + 1];
                        }
                        _benapproval_.pop();
                        _benApproval = _benapproval_;
                        break;
                    }
                }
                break;
            }
        }
    }

    /**
     * @dev editApproval - Edits the token information of the approval
     * @param uid string of the dApp identifier for the user
     * @param approvalId uint256 ID of the approval struct to modify
     * @param _contractAddress address being set for the approval
     * @param _tokenId uint256 tokenId being set of the approval
     * @param _tokenAmount uint256 amount of tokens in the approval
     * @param _tokenType string (ERC20 | ERC1155 | ERC721)
     *
     */
    function editApproval(
        string calldata uid,
        uint256 approvalId,
        address _contractAddress,
        uint256 _tokenId,
        uint256 _tokenAmount,
        string calldata _tokenType
    ) external {
        IMember(IProtocolDirectory(directoryContract).getMemberContract())
            .checkUIDofSender(uid, msg.sender);
        Approvals[] storage approval_ = MemberApprovals[uid];
        for (uint256 i; i < approval_.length; i++) {
            Approvals storage _userApproval = approval_[i];
            if (_userApproval.approvalId == approvalId) {
                if (_userApproval.active || _userApproval.claimed) {
                    revert NoApprovalExists();
                }

                TokenActions.checkAssetContract(
                    _contractAddress,
                    _tokenType,
                    _tokenId,
                    msg.sender,
                    _tokenAmount
                );

                if (_tokenAmount > 100 || _tokenAmount < 0) {
                    revert InvalidTokenRange();
                }
                _userApproval.token.tokenAddress = _contractAddress;
                _userApproval.token.tokenId = _tokenId;
                _userApproval.token.tokensAllocated = _tokenAmount;
                _userApproval.token.tokenType = _tokenType;

                emit ApprovalsEvent(
                    _userApproval._uid,
                    _userApproval.beneficiary.beneficiaryName,
                    _tokenId,
                    _tokenType,
                    _tokenAmount,
                    _userApproval.dateApproved,
                    approvalId,
                    _userApproval.claimExpiryTime,
                    0,
                    _userApproval.approvedWallet,
                    _userApproval.beneficiary.beneficiaryAddress,
                    _contractAddress,
                    _userApproval.claimed,
                    _userApproval.active
                );

                Approvals[]
                    storage _beneficiaryApproval = BeneficiaryClaimableAsset[
                        _userApproval.beneficiary.beneficiaryAddress
                    ];
                for (uint256 j; j < _beneficiaryApproval.length; j++) {
                    Approvals storage _benApproval = _beneficiaryApproval[j];
                    if (_benApproval.approvalId == approvalId) {
                        if (_benApproval.active || _benApproval.claimed) {
                            revert NoApprovalExists();
                        }
                        _benApproval.token.tokenAddress = _contractAddress;
                        _benApproval.token.tokenId = _tokenId;
                        _benApproval.token.tokensAllocated = _tokenAmount;
                        _benApproval.token.tokenType = _tokenType;
                        break;
                    }
                }
                break;
            }
        }
        IMembership(IMembershipAddress).redeemUpdate(uid);
    }

    /**
     * @notice Function to check if user has membership
     * @param _uid string of the dApp identifier for the user
     *
     */

    function checkUserHasMembership(string memory _uid) public view {
        IMembership _membership = IMembership(IMembershipAddress);
        if (_membership.checkIfMembershipActive(_uid) == false) {
            revert NoMembershipExists();
        } else {
            if (
                IMembership(IMembershipAddress)
                    .getMembership(_uid)
                    .updatesPerYear <= 0
            ) {
                revert InsufficientTopups();
            }
        }
    }
}