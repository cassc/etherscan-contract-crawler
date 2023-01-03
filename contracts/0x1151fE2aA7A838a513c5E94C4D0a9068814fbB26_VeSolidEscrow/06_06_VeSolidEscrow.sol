// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface IVeV2 {
    function locked(uint256) external view returns (int128 amount, uint256 end);

    function merge(uint256 _from, uint256 _to) external;

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external;

    function split(uint256 _from, uint256 _amount) external returns (uint256);

    function ownerOf(uint256 _tokenId) external view returns (address);

    function setApprovalForAll(address operator, bool _approved) external;

    function approve(address to, uint256 tokenId) external;

    function getApproved(uint256 _tokenId) external view returns (address);
}

interface IVeDistV2 {
    function claim(uint256 _tokenId) external returns (uint256);

    function claimable(uint256 _tokenId) external view returns (uint256);
}

interface IMinterV2 {
    function update_period() external returns (uint256);

    function active_period() external view returns (uint256);
}

interface IVoterV2 {
    function reset(uint256 _tokenId) external;
}

contract VeSolidEscrowManager is Ownable {
    using SafeERC20 for IERC20;

    struct EscrowData {
        bool goodStanding;
        uint128 tokenId;
        uint40 unlockTime;
    }

    address[] public escrows;
    mapping(uint256 => bool) public isEscrowed; // tokenId => is escrowed
    mapping(uint256 => address) public tokenIdToEscrow; // tokenId => escrow address
    mapping(address => EscrowData) public escrowData; // escrow address => tokenId

    mapping(uint256 => uint256) internal tokenIdLockedAmount; // tokenId => last locked amount

    // Solidly Addresses
    IVeV2 public immutable ve;
    IVeDistV2 public immutable veDist;
    IMinterV2 public immutable minter;
    IVoterV2 public immutable voter;

    mapping(bytes4 => bool) internal isBlockedVeMethod;

    // Temp storage just for creating escrows
    address public tempAddress;

    /**************************************** 
	 	 			 Events
	 ****************************************/
    event EscrowCreated(
        uint256 indexed tokenId,
        address indexed operator,
        address indexed escrow,
        uint256 unlockTime
    );

    event VeNftRevoked(uint256 indexed tokenId, address escrow);

    event Recovered(address tokenAddress, uint256 amountOrTokenId);

    event Standing(address escrowAddress, bool goodStanding);

    /**************************************** 
	 	 			Modifiers
	 ****************************************/

    /**
     * @notice Checks whether the veNFT stays in the escrow after a user interacts with the escrow
     */
    modifier veNftUnchanged(
        address escrow,
        address to,
        bytes calldata data
    ) {
        EscrowData memory _escrowData = escrowData[escrow];
        uint256 _tokenId = _escrowData.tokenId;
        require(_tokenId != 0, "Not an escrow");
        require(_escrowData.goodStanding, "Escrow in bad standing");

        bool _escrowInEffect = _escrowData.unlockTime > block.timestamp;

        if (_escrowInEffect) {
            // Check if method is approved if interacting with ve
            if (to == address(ve)) {
                bytes4 selector = bytes4(data);
                require(!isBlockedVeMethod[selector], "Cannot approve veNFTs");
            }

            // Update period if epoch changed
            if (block.timestamp >= minter.active_period() + 1 weeks) {
                minter.update_period();
            }
            tokenIdLockedAmount[_tokenId] = lockedAndClaimable(_tokenId);
        }

        _;

        if (_escrowInEffect) {
            // Check if veNFT is still in escrow
            require(ve.ownerOf(_tokenId) == escrow, "veNFT not in escrow");

            // Check if locked amount decreased
            require(
                lockedAndClaimable(_tokenId) >= tokenIdLockedAmount[_tokenId],
                "Locked amount decreased"
            );

            // Check if manger still has approval
            require(
                ve.getApproved(_tokenId) == address(this),
                "Manager no longer approved"
            );
        }
    }

    /**************************************** 
	 	 			Constructor
	 ****************************************/
    constructor(
        IVeV2 _ve,
        IVeDistV2 _veDist,
        IMinterV2 _minter,
        IVoterV2 _voter
    ) Ownable() {
        ve = _ve;
        veDist = _veDist;
        minter = _minter;
        voter = _voter;

        // Block escrows from approving veNFTs
        isBlockedVeMethod[IVeV2.approve.selector] = true;
        isBlockedVeMethod[IVeV2.setApprovalForAll.selector] = true;
    }

    /**************************************** 
	 	 		Restricted Methods
	 ****************************************/

    function createNewEscrow(
        uint256 tokenId,
        address operator,
        uint256 duration
    ) external onlyOwner {
        require(!isEscrowed[tokenId], "Already in escrow");
        isEscrowed[tokenId] = true;

        // Create escrow contract
        bytes32 salt = keccak256(abi.encode(tokenId, operator));

        tempAddress = operator;

        address escrowAddress = address(new VeSolidEscrow{salt: salt}());

        // Send veNFT to escrow
        ve.safeTransferFrom(msg.sender, escrowAddress, tokenId);

        // Approve manager to revoke veNFT if needed in the future
        (bool success, ) = VeSolidEscrow(escrowAddress)._executeCall(
            address(ve),
            0,
            abi.encodeWithSignature(
                "approve(address,uint256)",
                address(this),
                tokenId
            )
        );
        require(success, "Approval failed");

        // Record escrow address
        escrows.push(escrowAddress);
        EscrowData memory _escrowData = EscrowData({
            tokenId: uint128(tokenId),
            unlockTime: uint40(block.timestamp + duration), // Won't run into problems for 34000 years
            goodStanding: true
        });
        escrowData[escrowAddress] = _escrowData;
        tokenIdToEscrow[tokenId] = escrowAddress;

        emit EscrowCreated(
            tokenId,
            operator,
            escrowAddress,
            block.timestamp + duration
        );
    }

    /**
     * @notice Used to set an escrow's standing (to true = good or false = bad)
     */
    function setStanding(uint256 tokenId, bool standingStatus)
        external
        onlyOwner
    {
        address escrowAddress = tokenIdToEscrow[tokenId];
        require(escrowAddress != address(0), "Not an escrow");
        EscrowData memory _escrowData = escrowData[escrowAddress];
        require(_escrowData.unlockTime > block.timestamp, "Escrow expired");

        // Change and emit standing state if different
        if (_escrowData.goodStanding != standingStatus) {
            escrowData[escrowAddress].goodStanding = standingStatus;

            emit Standing(escrowAddress, standingStatus);
        }
    }

    /**
     * @notice Used to detach gauges before revoking
     */
    function detachGauges(uint256 tokenId, address[] calldata gauges)
        external
        onlyOwner
    {
        address _escrow = tokenIdToEscrow[tokenId];
        require(!escrowData[_escrow].goodStanding, "Escrow in good standing");

        bytes memory data = abi.encodeWithSignature(
            "withdrawToken(uint256,uint256)",
            0,
            tokenId
        );

        for (uint256 i = 0; i < gauges.length; i++) {
            VeSolidEscrow(_escrow)._executeCall(gauges[i], 0, data);
        }
    }

    /**
     * @notice Used to reset votes before revoking
     */
    function resetVotes(uint256 tokenId) external onlyOwner {
        address _escrow = tokenIdToEscrow[tokenId];
        require(!escrowData[_escrow].goodStanding, "Escrow in good standing");

        voter.reset(tokenId);
    }

    /**
     * @notice Revokes the veNFT if a user misbehaves
     */
    function revokeNft(uint256 tokenId) external onlyOwner {
        address _escrow = tokenIdToEscrow[tokenId];
        require(!escrowData[_escrow].goodStanding, "Escrow in good standing");

        // Transfer veNFT
        ve.safeTransferFrom(_escrow, owner(), tokenId);

        // Update states
        isEscrowed[tokenId] = false;
        EscrowData memory _escrowData = EscrowData({
            goodStanding: true, // So the user can still interact with the contract after the veNFT is revoked
            tokenId: uint128(tokenId),
            unlockTime: uint40(block.timestamp) // So the user can still interact with the contract after the veNFT is revoked
        });
        escrowData[_escrow] = _escrowData;

        emit VeNftRevoked(tokenId, _escrow);
    }

    function recoverERC20(address _tokenAddress, uint256 _tokenAmount)
        external
        onlyOwner
    {
        IERC20(_tokenAddress).safeTransfer(owner(), _tokenAmount);
        emit Recovered(_tokenAddress, _tokenAmount);
    }

    /**************************************** 
	 	 		 View Methods
	 ****************************************/

    function lockedAndClaimable(uint256 tokenId)
        internal
        view
        returns (uint256)
    {
        (int256 lockedAmount, ) = ve.locked(tokenId);
        uint256 claimableAmount = veDist.claimable(tokenId);
        return uint256(lockedAmount) + claimableAmount;
    }

    /**************************************** 
	 	 		 Wrapper Methods
	 ****************************************/
    /**
     * @notice Called by escrow contracts, checks whether interactions jeopardizes the veNFT
     */
    function wrappedExecuteCall(
        address to,
        uint256 value,
        bytes calldata data
    ) external payable veNftUnchanged(msg.sender, to, data) {
        (bool success, bytes memory returnData) = VeSolidEscrow(msg.sender)
            ._executeCall{value: msg.value}(to, value, data);

        require(success == true, "Transaction failed");
    }

    /**************************************** 
                     ERC721
     ****************************************/

    /**
     * @notice This contract should not receive NFTs
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4) {
        revert("This contract doesn't accept NFTs");
    }
}

/**
 * @notice  Manager should not be able to do anything other than revoking the veNFT
 * 			Operator should be able to do anything other than approvals as long as the
 * 			veNFT remains in the escrow
 */
contract VeSolidEscrow {
    address public immutable manager; // Immutable so there's no way to bypass onlyManager

    mapping(address => bool) public isOperator; // People who can access the veNFT in this contract

    /**************************************** 
                      Events
     ****************************************/

    event OperatorStatus(address indexed operator, bool state);

    /**************************************** 
                     Modifiers
     ****************************************/
    modifier onlyManager() {
        require(msg.sender == manager, "Only manager");
        _;
    }

    modifier onlyOperator() {
        require(isOperator[msg.sender], "Only Operator");
        _;
    }

    /**************************************** 
                    Constructor
     ****************************************/

    constructor() {
        manager = msg.sender;
        address _operator = VeSolidEscrowManager(msg.sender).tempAddress();
        isOperator[_operator] = true;
        emit OperatorStatus(_operator, true);
    }

    /**************************************** 
                 User Interactions
     ****************************************/
    /**
     * @notice Sets operator status
     * @dev Operators are also allowed to add other operators
     */
    function setOperator(address operator, bool state) external onlyOperator {
        if (isOperator[operator] != state) {
            isOperator[operator] = state;
            emit OperatorStatus(operator, state);
        }
    }

    /**
     * @notice Allows the user to do anything except approving the veNFT
     * @dev Manager checks whether the veNFT stays in escrow at the end of the tx
     */
    function executeCall(
        address to,
        uint256 value,
        bytes memory data
    ) external payable onlyOperator {
        VeSolidEscrowManager(manager).wrappedExecuteCall{value: msg.value}(
            to,
            value,
            data
        );
    }

    /**************************************** 
                  Wrapped Call
     ****************************************/

    /**
     * @notice Internal notation because this is only reachable via executeCall() callable by operators
     * @dev The only time manager's owner has access to this is during revoking which approves the
     * 		veNFT to the manager and detaches from gauges.
     */
    function _executeCall(
        address to,
        uint256 value,
        bytes memory data
    )
        external
        payable
        onlyManager
        returns (bool success, bytes memory returnData)
    {
        (success, returnData) = to.call{value: value}(data);

        // Bubble revert reason up if reverted
        if (!success) {
            assembly {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }
    }

    /**************************************** 
                     ERC721
     ****************************************/

    /**
     * @notice Mandatory ERC721 receiver
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4) {
        return this.onERC721Received.selector;
    }
}