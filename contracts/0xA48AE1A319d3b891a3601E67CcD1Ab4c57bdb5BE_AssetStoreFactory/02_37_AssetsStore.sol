//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./libraries/TokenActions.sol";
import "./libraries/Errors.sol";
import "./interfaces/IProtocolDirectory.sol";
import "./interfaces/IMember.sol";
import "./interfaces/IMembership.sol";
import "./interfaces/IAssetStore.sol";
import "./interfaces/IAssetStoreFactory.sol";
import "./structs/MemberStruct.sol";
import "./structs/TokenStruct.sol";
import "./structs/ApprovalsStruct.sol";

//

/**
 * @title AssetsStore
 * @notice This contract is deployed by the AssetsStoreFactory.sol
 * and is the contract that holds the approvals for a user's directives
 *
 * @dev The ownership of this contract is held by the deployer factory
 *
 */

contract AssetsStore is IAssetStore, Ownable, ReentrancyGuard {
    // Returns token Approvals for specific UID
    mapping(string => Approvals[]) private MemberApprovals;

    // Mapping Beneficiaries to a specific Approval for Claiming
    mapping(address => Approvals[]) private BeneficiaryClaimableAsset;

    // Storing ApprovalId for different approvals stored
    uint256 private _approvalsId;

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
        address approvedWallet,
        string beneficiaryName,
        address beneficiaryAddress,
        uint256 tokenId,
        address tokenAddress,
        string tokenType,
        uint256 tokensAllocated,
        uint256 dateApproved,
        bool claimed,
        bool active,
        uint256 approvalId,
        uint256 claimExpiryTime,
        uint256 approvedTokenAmount
    );

    /**
     * @dev Modifier to ensure that the user exists within the ecosystem
     * @param uid string of the central identifier used for this user within the dApp
     *
     */
    modifier checkIfMember(string memory uid) {
        address IMemberAddress = IProtocolDirectory(directoryContract)
            .getMemberContract();
        if (bytes(IMember(IMemberAddress).getMember(uid).uid).length == 0) {
            revert(Errors.AS_USER_DNE);
        }
        _;
    }

    /**
     * @dev Modifier checking that only the RelayerContract can invoke certain functions
     *
     */
    modifier onlyRelayerContract() {
        address relayerAddress = IProtocolDirectory(directoryContract)
            .getRelayerContract();
        if (msg.sender != relayerAddress) {
            revert(Errors.AS_ONLY_RELAY);
        }
        _;
    }

    /**
     * @dev Modifier to ensure a function can only be invoked by
     * the ChainlinkOperationsContract
     */
    modifier onlyChainlinkOperationsContract() {
        address linkOpsAddress = IProtocolDirectory(directoryContract)
            .getChainlinkOperationsContract();
        if (msg.sender != linkOpsAddress) {
            revert(Errors.AS_ONLY_CHAINLINK_OPS);
        }
        _;
    }

    /**
     * @dev initialize - Initializes the function for Ownable and Reentrancy.
     * @param _directoryContract address of the ProtocolDirectory Contract
     * @param _membershipAddress address of the Contract deployed for this
     * user's membership
     */
    constructor(address _directoryContract, address _membershipAddress) {
        directoryContract = _directoryContract;
        IMembershipAddress = _membershipAddress;
        _approvalsId = 0;
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
        address[] memory _contractAddress,
        address[] memory _beneficiaries,
        string[] memory _beneficiaryNames,
        bool[] memory _beneficiaryIsCharity,
        string[] memory _tokenTypes,
        uint256[] memory _tokenIds,
        uint256[] memory _tokenAmount,
        uint256[] memory _backUpTokenIds,
        uint256[] memory _backupTokenAmount,
        address[] memory _backUpWallets,
        address[] memory _backUpAddresses,
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
            uid,
            msg.sender,
            true
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
        address[] memory _contractAddress,
        uint256[] memory _tokenIds,
        address[] memory _beneficiaries,
        string[] memory _beneficiaryNames,
        bool[] memory _beneficiaryIsCharity,
        uint256[] memory _tokenAmount,
        string[] memory _tokenTypes,
        string memory _memberUID
    ) public {
        if (
            _tokenIds.length != _contractAddress.length ||
            _beneficiaryNames.length != _beneficiaries.length ||
            _tokenIds.length != _beneficiaries.length
        ) {
            revert(Errors.AS_DIFF_LENGTHS);
        }

        address IMemberAddress = IProtocolDirectory(directoryContract)
            .getMemberContract();
        if ((IMember(IMemberAddress).checkIfUIDExists(msg.sender) == false)) {
            IMember(IMemberAddress).createMember(_memberUID, msg.sender);
        }
        checkUserHasMembership(_memberUID);

        member memory _member = IMember(IMemberAddress).getMember(_memberUID);
        if (
            msg.sender != IMember(IMemberAddress).getPrimaryWallet(_memberUID)
        ) {
            revert(Errors.AS_ONLY_PRIMARY_WALLET);
        }

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            address contractAddress = _contractAddress[i];
            uint256 tokenId_ = _tokenIds[i];
            address beneficiary_ = _beneficiaries[i];
            string memory beneficiaryName_ = _beneficiaryNames[i];
            string memory tokenType = _tokenTypes[i];
            bool isCharity = _beneficiaryIsCharity[i];
            uint256 tokenAmount = _tokenAmount[i];

            TokenActions.checkAssetContract(contractAddress, tokenType);
            if (tokenAmount > 100 || tokenAmount < 0) {
                revert(Errors.AS_INVALID_TOKEN_RANGE);
            }
            Beneficiary memory beneficiary = Beneficiary(
                beneficiary_,
                beneficiaryName_,
                isCharity
            );
            Token memory _token = Token(
                tokenId_,
                contractAddress,
                tokenType,
                tokenAmount
            );

            uint256 _dateApproved = block.timestamp;
            _storeAssets(
                _memberUID,
                _member,
                msg.sender,
                beneficiary,
                _token,
                _dateApproved
            );
            emit ApprovalsEvent(
                _member.uid,
                msg.sender,
                beneficiary.beneficiaryName,
                beneficiary.beneficiaryAddress,
                _token.tokenId,
                _token.tokenAddress,
                _token.tokenType,
                _token.tokensAllocated,
                _dateApproved,
                false,
                false,
                _approvalsId,
                0,
                0
            );
        }
        IMembership(IMembershipAddress).redeemUpdate(_memberUID);
    }

    /**
     * @dev _storeAssets - Internal function to store assets
     * @param uid string string of the dApp identifier for the user
     * @param _member member struct storing relevant data for the user
     * @param user address address of the user
     * @param _beneificiary Beneficiary struct storing data representing the beneficiary
     * @param _token Token struct containing information of the asset in the will
     * @param _dateApproved uint256 block timestamp when this function is called
     *
     */
    function _storeAssets(
        string memory uid,
        member memory _member,
        address user,
        Beneficiary memory _beneificiary,
        Token memory _token,
        uint256 _dateApproved
    ) internal {
        Approvals memory approval = Approvals(
            _member,
            user,
            _beneificiary,
            _token,
            _dateApproved,
            false,
            false,
            ++_approvalsId,
            0,
            0
        );

        BeneficiaryClaimableAsset[_beneificiary.beneficiaryAddress].push(
            approval
        );
        MemberApprovals[uid].push(approval);
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
        onlyOwner
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
                _approvals[i].claimed = true;
                _approvals[i].active = false;
                emit ApprovalsEvent(
                    _approvals[i].Member.uid,
                    _approvals[i].approvedWallet,
                    _approvals[i].beneficiary.beneficiaryName,
                    _approvals[i].beneficiary.beneficiaryAddress,
                    // _approvals[i].beneficiary.isCharity,
                    _approvals[i].token.tokenId,
                    _approvals[i].token.tokenAddress,
                    _approvals[i].token.tokenType,
                    _approvals[i].token.tokensAllocated,
                    _approvals[i].dateApproved,
                    _approvals[i].claimed,
                    _approvals[i].active,
                    _approvals[i].approvalId,
                    _approvals[i].claimExpiryTime,
                    _approvals[i].approvedTokenAmount
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
                _approvals[i].claimed = true;
                _approvals[i].active = false;
                emit ApprovalsEvent(
                    _approvals[i].Member.uid,
                    _approvals[i].approvedWallet,
                    _approvals[i].beneficiary.beneficiaryName,
                    _approvals[i].beneficiary.beneficiaryAddress,
                    // _approvals[i].beneficiary.isCharity,
                    _approvals[i].token.tokenId,
                    _approvals[i].token.tokenAddress,
                    _approvals[i].token.tokenType,
                    _approvals[i].token.tokensAllocated,
                    _approvals[i].dateApproved,
                    _approvals[i].claimed,
                    _approvals[i].active,
                    _approvals[i].approvalId,
                    _approvals[i].claimExpiryTime,
                    _approvals[i].approvedTokenAmount
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
        nonReentrant
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

                    setApprovalClaimed(uid, _approval[i].approvalId);
                    setBenApprovalClaimed(
                        _approval[i].beneficiary.beneficiaryAddress,
                        _approval[i].approvalId
                    );
                    bool sent = ERC20.transferFrom(
                        _approval[i].approvedWallet,
                        TransferPool,
                        _tokenAmount
                    );
                }

                // transfer erc721
                if (
                    keccak256(
                        abi.encodePacked((_approval[i].token.tokenType))
                    ) == keccak256(abi.encodePacked(("ERC721")))
                ) {
                    IERC721 ERC721 = IERC721(_approval[i].token.tokenAddress);

                    setApprovalClaimed(uid, _approval[i].approvalId);
                    setBenApprovalClaimed(
                        _approval[i].beneficiary.beneficiaryAddress,
                        _approval[i].approvalId
                    );
                    ERC721.safeTransferFrom(
                        _approval[i].approvedWallet,
                        TransferPool,
                        _approval[i].token.tokenId
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
                    setApprovalClaimed(uid, _approval[i].approvalId);
                    setBenApprovalClaimed(
                        _approval[i].beneficiary.beneficiaryAddress,
                        _approval[i].approvalId
                    );
                    ERC1155.safeTransferFrom(
                        _approval[i].approvedWallet,
                        TransferPool,
                        _approval[i].token.tokenId,
                        _tokenAmount,
                        data
                    );
                }
            }
        }
    }

    /**
     * @dev claimAsset - Function to claim Asset from a specific UID
     * @param uid string of the dApp identifier for the user
     * @param approvalId_ uint256 id of the specific approval being claimed
     * @param benUID string of the dApp identifier for the beneficiary claiming the asset
     *
     */
    function claimAsset(
        string memory uid,
        uint256 approvalId_,
        string memory benUID
    ) external nonReentrant {
        address IMemberAddress = IProtocolDirectory(directoryContract)
            .getMemberContract();
        if ((IMember(IMemberAddress).checkIfUIDExists(msg.sender) == false)) {
            IMember(IMemberAddress).createMember(benUID, msg.sender);
        }
        Approvals[] storage _approval = BeneficiaryClaimableAsset[msg.sender];
        for (uint256 i = 0; i < _approval.length; i++) {
            if (
                keccak256(abi.encodePacked((_approval[i].Member.uid))) ==
                keccak256(abi.encodePacked((uid)))
            ) {
                if (_approval[i].beneficiary.beneficiaryAddress != msg.sender) {
                    revert(Errors.AS_ONLY_BENEFICIARY);
                }
                if (
                    _approval[i].active == true && _approval[i].claimed == false
                ) {
                    if (_approval[i].approvalId == approvalId_) {
                        // transfer erc20
                        if (
                            keccak256(
                                abi.encodePacked((_approval[i].token.tokenType))
                            ) == keccak256(abi.encodePacked(("ERC20")))
                        ) {
                            setApprovalClaimed(uid, _approval[i].approvalId);
                            TokenActions.sendERC20(_approval[i]);
                        }

                        // transfer erc721
                        if (
                            keccak256(
                                abi.encodePacked((_approval[i].token.tokenType))
                            ) == keccak256(abi.encodePacked(("ERC721")))
                        ) {
                            IERC721 ERC721 = IERC721(
                                _approval[i].token.tokenAddress
                            );
                            _approval[i].claimed = true;
                            setApprovalClaimed(uid, _approval[i].approvalId);

                            ERC721.safeTransferFrom(
                                _approval[i].approvedWallet,
                                _approval[i].beneficiary.beneficiaryAddress,
                                _approval[i].token.tokenId
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
                            uint256 _tokenAmount = (
                                _approval[i].approvedTokenAmount
                            );

                            bytes memory data;
                            _approval[i].claimed = true;
                            setApprovalClaimed(uid, _approval[i].approvalId);

                            ERC1155.safeTransferFrom(
                                _approval[i].approvedWallet,
                                _approval[i].beneficiary.beneficiaryAddress,
                                _approval[i].token.tokenId,
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
        string memory _uid
    ) external onlyRelayerContract nonReentrant {
        // look to see if this address is a charity
        Approvals[]
            storage charityBeneficiaryApprovals = BeneficiaryClaimableAsset[
                _charityBeneficiaryAddress
            ];
        if (charityBeneficiaryApprovals.length == 0) {
            revert(Errors.AS_NO_APPROVALS);
        }
        for (uint256 i = 0; i < charityBeneficiaryApprovals.length; i++) {
            if (!charityBeneficiaryApprovals[i].beneficiary.isCharity) {
                revert(Errors.AS_NOT_CHARITY);
            }
            if (
                charityBeneficiaryApprovals[i].active == true &&
                charityBeneficiaryApprovals[i].claimed == false &&
                (keccak256(
                    abi.encodePacked(
                        (charityBeneficiaryApprovals[i].token.tokenType)
                    )
                ) == keccak256(abi.encodePacked(("ERC20"))))
            ) {
                setApprovalClaimed(
                    _uid,
                    charityBeneficiaryApprovals[i].approvalId
                );
                setBenApprovalClaimed(
                    _charityBeneficiaryAddress,
                    charityBeneficiaryApprovals[i].approvalId
                );
                TokenActions.sendERC20(charityBeneficiaryApprovals[i]);
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
    function setApprovalActive(string memory uid)
        external
        onlyChainlinkOperationsContract
    {
        Approvals[] storage _approvals = MemberApprovals[uid];
        for (uint256 i = 0; i < _approvals.length; i++) {
            _approvals[i].active = true;
            _approvals[i].claimExpiryTime = block.timestamp + 31536000;
            Approvals[] storage approvals = BeneficiaryClaimableAsset[
                _approvals[i].beneficiary.beneficiaryAddress
            ];
            for (uint256 j = 0; j < approvals.length; j++) {
                if (
                    keccak256(abi.encodePacked((approvals[j].Member.uid))) ==
                    keccak256(abi.encodePacked((uid)))
                ) {
                    /// @notice check if is ERC20 for preAllocating then claiming
                    if (
                        keccak256(
                            abi.encodePacked((approvals[j].token.tokenType))
                        ) == keccak256(abi.encodePacked(("ERC20")))
                    ) {
                        IERC20 claimingERC20 = IERC20(
                            approvals[j].token.tokenAddress
                        );
                        /// @notice setting fixed tokenAmount to claim later
                        approvals[j].approvedTokenAmount =
                            (approvals[j].token.tokensAllocated *
                                claimingERC20.balanceOf(
                                    approvals[j].approvedWallet
                                )) /
                            100;
                    }

                    if (
                        keccak256(
                            abi.encodePacked((approvals[j].token.tokenType))
                        ) == keccak256(abi.encodePacked(("ERC1155")))
                    ) {
                        IERC1155 claimingERC1155 = IERC1155(
                            approvals[j].token.tokenAddress
                        );
                        approvals[j].approvedTokenAmount =
                            (approvals[j].token.tokensAllocated *
                                claimingERC1155.balanceOf(
                                    approvals[j].approvedWallet,
                                    approvals[j].token.tokenId
                                )) /
                            100;
                    }

                    approvals[j].active = true;
                    approvals[j].claimExpiryTime = block.timestamp + 31536000;

                    emit ApprovalsEvent(
                        approvals[j].Member.uid,
                        approvals[j].approvedWallet,
                        approvals[j].beneficiary.beneficiaryName,
                        approvals[j].beneficiary.beneficiaryAddress,
                        // approvals[j].beneficiary.isCharity,
                        approvals[j].token.tokenId,
                        approvals[j].token.tokenAddress,
                        approvals[j].token.tokenType,
                        approvals[j].token.tokensAllocated,
                        approvals[j].dateApproved,
                        approvals[j].claimed,
                        approvals[j].active,
                        approvals[j].approvalId,
                        approvals[j].claimExpiryTime,
                        approvals[j].approvedTokenAmount
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
    function deleteApproval(string memory uid, uint256 approvalId) external {
        Approvals[] storage approval_ = MemberApprovals[uid];
        for (uint256 i = 0; i < approval_.length; i++) {
            if (approval_[i].approvalId == approvalId) {
                Approvals[] storage _approval_ = MemberApprovals[uid];
                for (uint256 j = i; j < _approval_.length - 1; j++) {
                    _approval_[j] = _approval_[j + 1];
                }
                _approval_.pop();
                approval_ = _approval_;

                Approvals[] storage _benApproval = BeneficiaryClaimableAsset[
                    approval_[i].beneficiary.beneficiaryAddress
                ];
                for (uint256 k = 0; k < _benApproval.length; k++) {
                    if (_benApproval[k].approvalId == approvalId) {
                        Approvals[]
                            storage _benapproval_ = BeneficiaryClaimableAsset[
                                _benApproval[k].beneficiary.beneficiaryAddress
                            ];
                        for (uint256 l = k; k < _benapproval_.length - 1; k++) {
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
        string memory uid,
        uint256 approvalId,
        address _contractAddress,
        uint256 _tokenId,
        uint256 _tokenAmount,
        string memory _tokenType
    ) external checkIfMember(uid) {
        IMember(IProtocolDirectory(directoryContract).getMemberContract())
            .checkUIDofSender(uid, msg.sender);
        Approvals[] storage approval_ = MemberApprovals[uid];
        for (uint256 i = 0; i < approval_.length; i++) {
            if (approval_[i].approvalId == approvalId) {
                if (approval_[i].active || approval_[i].claimed) {
                    revert(Errors.AS_INVALID_APPROVAL);
                }

                TokenActions.checkAssetContract(_contractAddress, _tokenType);
                if (_tokenAmount > 100 || _tokenAmount < 0) {
                    revert(Errors.AS_INVALID_TOKEN_RANGE);
                }
                approval_[i].token.tokenAddress = _contractAddress;
                approval_[i].token.tokenId = _tokenId;
                approval_[i].token.tokensAllocated = _tokenAmount;
                approval_[i].token.tokenType = _tokenType;

                emit ApprovalsEvent(
                    approval_[i].Member.uid,
                    approval_[i].approvedWallet,
                    approval_[i].beneficiary.beneficiaryName,
                    approval_[i].beneficiary.beneficiaryAddress,
                    // approval_[i].beneficiary.isCharity,
                    _tokenId,
                    _contractAddress,
                    _tokenType,
                    _tokenAmount,
                    approval_[i].dateApproved,
                    approval_[i].claimed,
                    approval_[i].active,
                    approvalId,
                    approval_[i].claimExpiryTime,
                    0
                );

                Approvals[]
                    storage _beneficiaryApproval = BeneficiaryClaimableAsset[
                        approval_[i].beneficiary.beneficiaryAddress
                    ];
                for (uint256 j = 0; j < _beneficiaryApproval.length; j++) {
                    if (_beneficiaryApproval[j].approvalId == approvalId) {
                        if (
                            _beneficiaryApproval[j].active ||
                            _beneficiaryApproval[j].claimed
                        ) {
                            revert(Errors.AS_INVALID_APPROVAL);
                        }
                        _beneficiaryApproval[j]
                            .token
                            .tokenAddress = _contractAddress;
                        _beneficiaryApproval[j].token.tokenId = _tokenId;
                        _beneficiaryApproval[j]
                            .token
                            .tokensAllocated = _tokenAmount;
                        _beneficiaryApproval[j].token.tokenType = _tokenType;
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
        bool _MembershipActive = _membership.checkIfMembershipActive(_uid);
        if (_MembershipActive == false) {
            revert(Errors.AS_NO_MEMBERSHIP);
        } else {
            MembershipStruct memory Membership = IMembership(IMembershipAddress)
                .getMembership(_uid);
            if (Membership.updatesPerYear <= 0) {
                revert(Errors.AS_NEED_TOP);
            }
        }
    }
}