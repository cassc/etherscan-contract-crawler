//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Metadata.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/proxy/Initializable.sol";
import "@openzeppelin/contracts/math/Math.sol";
import "../../core/governance/Governed.sol";
import "../../core/work/libraries/CommitMinter.sol";
import "../../core/work/libraries/GrantReceiver.sol";
import "../../core/work/interfaces/IStableReserve.sol";
import "../../core/work/interfaces/IContributionBoard.sol";
import "../../core/dividend/libraries/Distributor.sol";
import "../../core/dividend/interfaces/IDividendPool.sol";
import "../../utils/IERC1620.sol";
import "../../utils/Utils.sol";

contract ContributionBoard is
    CommitMinter,
    GrantReceiver,
    Distributor,
    Governed,
    ReentrancyGuard,
    Initializable,
    ERC1155Burnable,
    IContributionBoard
{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using ECDSA for bytes32;
    using Utils for address[];

    address private _sablier;
    IERC721 private _project;
    mapping(uint256 => uint256) private _projectFund;
    mapping(uint256 => uint256) private _totalSupplyOf;
    mapping(uint256 => uint256) private _maxSupplyOf;
    mapping(uint256 => uint256) private _minimumShare;
    mapping(uint256 => bool) private _fundingPaused;
    mapping(uint256 => bool) private _finalized;
    mapping(uint256 => uint256) private _projectOf;
    mapping(uint256 => uint256[]) private _streams;
    mapping(uint256 => address[]) private _contributors;

    constructor() ERC1155("") {
        // this will not be called
    }

    function initialize(
        address project_,
        address gov_,
        address dividendPool_,
        address stableReserve_,
        address commit_,
        address sablier_
    ) public initializer {
        CommitMinter._setup(stableReserve_, commit_);
        Distributor._setup(dividendPool_);
        _project = IERC721(project_);
        _sablier = sablier_;
        Governed.initialize(gov_);
        _setURI("");

        // register the supported interfaces to conform to ERC1155 via ERC165
        bytes4 _INTERFACE_ID_ERC165 = 0x01ffc9a7;
        bytes4 _INTERFACE_ID_ERC1155 = 0xd9b67a26;
        bytes4 _INTERFACE_ID_ERC1155_METADATA_URI = 0x0e89341c;
        _registerInterface(_INTERFACE_ID_ERC165);
        _registerInterface(_INTERFACE_ID_ERC1155);
        _registerInterface(_INTERFACE_ID_ERC1155_METADATA_URI);
    }

    modifier onlyStableReserve() {
        require(
            address(stableReserve) == msg.sender,
            "Only the stable reserves can call this function"
        );
        _;
    }

    modifier onlyProjectOwner(uint256 projId) {
        require(_project.ownerOf(projId) == msg.sender, "Not authorized");
        _;
    }

    function addProjectFund(uint256 projId, uint256 amount) public override {
        require(!_fundingPaused[projId], "Should resume funding");
        IERC20(commitToken).safeTransferFrom(msg.sender, address(this), amount);
        uint256 updated = _projectFund[projId].add(amount);
        _projectFund[projId] = updated;
        if (_initialContributorShareProgram(projId)) {
            // record funding
            _recordContribution(msg.sender, projId, amount);
        }
    }

    function startInitialContributorShareProgram(
        uint256 projectId,
        uint256 minimumShare_,
        uint256 maxContribution
    ) public override onlyProjectOwner(projectId) {
        require(0 < minimumShare_, "Should be greater than 0");
        require(minimumShare_ < 10000, "Cannot be greater than denominator");
        require(_minimumShare[projectId] == 0, "Funding is already enabled.");
        _minimumShare[projectId] = minimumShare_;
        _setMaxContribution(projectId, maxContribution);
    }

    /**
     * @notice Usually the total supply = funded + paid. If you want to raise
     *         10000 COMMITs you should set the max contribution at least 20000.
     */
    function setMaxContribution(uint256 projectId, uint256 maxContribution)
        public
        override
        onlyProjectOwner(projectId)
    {
        _setMaxContribution(projectId, maxContribution);
    }

    function pauseFunding(uint256 projectId)
        public
        override
        onlyProjectOwner(projectId)
    {
        require(!_fundingPaused[projectId], "Already paused");
        _fundingPaused[projectId] = true;
    }

    function resumeFunding(uint256 projectId)
        public
        override
        onlyProjectOwner(projectId)
    {
        require(_fundingPaused[projectId], "Already unpaused");
        _fundingPaused[projectId] = false;
    }

    function compensate(
        uint256 projectId,
        address to,
        uint256 amount
    ) public override onlyProjectOwner(projectId) {
        require(_projectFund[projectId] >= amount, "Not enough fund.");
        _projectFund[projectId] = _projectFund[projectId] - amount; // "require" protects underflow
        IERC20(commitToken).safeTransfer(to, amount);
        _recordContribution(to, projectId, amount);
        emit Payed(projectId, to, amount);
    }

    function compensateInStream(
        uint256 projectId,
        address to,
        uint256 amount,
        uint256 period
    ) public override onlyProjectOwner(projectId) {
        require(_projectFund[projectId] >= amount);
        _projectFund[projectId] = _projectFund[projectId] - amount; // "require" protects underflow
        _recordContribution(to, projectId, amount);
        IERC20(commitToken).approve(_sablier, amount); // approve the transfer
        uint256 streamId =
            IERC1620(_sablier).createStream(
                to,
                amount,
                commitToken,
                block.timestamp,
                block.timestamp + period
            );

        _projectOf[streamId] = projectId;
        _streams[projectId].push(streamId);
        emit PayedInStream(projectId, to, amount, streamId);
    }

    function cancelStream(uint256 projectId, uint256 streamId)
        public
        override
        onlyProjectOwner(projectId)
    {
        require(projectOf(streamId) == projectId, "Invalid project id");

        (
            ,
            address recipient,
            uint256 deposit,
            ,
            uint256 startTime,
            uint256 stopTime,
            ,
            uint256 ratePerSecond
        ) = IERC1620(_sablier).getStream(streamId);

        uint256 earned = Math.min(block.timestamp, stopTime).sub(startTime);
        uint256 remaining = deposit.sub(ratePerSecond.mul(earned));
        require(IERC1620(_sablier).cancelStream(streamId), "Failed to cancel");

        _projectFund[projectId] = _projectFund[projectId].add(remaining);
        uint256 cancelContribution =
            Math.min(balanceOf(recipient, projectId), remaining);
        _burn(recipient, projectId, cancelContribution);
    }

    function recordContribution(
        address to,
        uint256 id,
        uint256 amount
    ) external override onlyProjectOwner(id) {
        require(
            !_initialContributorShareProgram(id),
            "Once it starts to get funding, you cannot record additional contribution"
        );
        require(
            _recordContribution(to, id, amount),
            "Cannot record after it's launched."
        );
    }

    function finalize(uint256 id) external override {
        require(
            msg.sender == address(_project),
            "this should be called only for upgrade"
        );
        require(!_finalized[id], "Already _finalized");
        _finalized[id] = true;
    }

    function receiveGrant(
        address currency,
        uint256 amount,
        bytes calldata data
    ) external override onlyStableReserve returns (bool result) {
        require(
            currency == commitToken,
            "Only can get $COMMIT token for its grant"
        );
        uint256 projId = abi.decode(data, (uint256));
        require(_project.ownerOf(projId) != address(0), "No budget owner");
        _projectFund[projId] = _projectFund[projId].add(amount);
        emit Grant(projId, amount);
        return true;
    }

    function sablier() public view override returns (address) {
        return _sablier;
    }

    function project() public view override returns (address) {
        return address(_project);
    }

    function projectFund(uint256 projId)
        public
        view
        override
        returns (uint256)
    {
        return _projectFund[projId];
    }

    function totalSupplyOf(uint256 projId)
        public
        view
        override
        returns (uint256)
    {
        return _totalSupplyOf[projId];
    }

    function maxSupplyOf(uint256 projId)
        public
        view
        override
        returns (uint256)
    {
        return _maxSupplyOf[projId];
    }

    function initialContributorShareProgram(uint256 projId)
        public
        view
        override
        returns (bool)
    {
        return _initialContributorShareProgram(projId);
    }

    function minimumShare(uint256 projId)
        public
        view
        override
        returns (uint256)
    {
        return _minimumShare[projId];
    }

    function fundingPaused(uint256 projId) public view override returns (bool) {
        return _fundingPaused[projId];
    }

    function finalized(uint256 projId) public view override returns (bool) {
        return _finalized[projId];
    }

    function projectOf(uint256 streamId)
        public
        view
        override
        returns (uint256 id)
    {
        return _projectOf[streamId];
    }

    function getStreams(uint256 projId)
        public
        view
        override
        returns (uint256[] memory)
    {
        return _streams[projId];
    }

    function getContributors(uint256 projId)
        public
        view
        override
        returns (address[] memory)
    {
        return _contributors[projId];
    }

    function uri(uint256 id)
        external
        view
        override(ERC1155, IContributionBoard)
        returns (string memory)
    {
        return IERC721Metadata(address(_project)).tokenURI(id);
    }

    function _setMaxContribution(uint256 id, uint256 maxContribution) internal {
        require(!_finalized[id], "DAO is launched. You cannot update it.");
        _maxSupplyOf[id] = maxContribution;
        emit NewMaxContribution(id, maxContribution);
    }

    function _recordContribution(
        address to,
        uint256 id,
        uint256 amount
    ) internal returns (bool) {
        if (_finalized[id]) return false;
        (bool exist, ) = _contributors[id].find(to);
        if (!exist) {
            _contributors[id].push(to);
        }
        bytes memory zero;
        _mint(to, id, amount, zero);
        return true;
    }

    function _mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal override {
        super._mint(account, id, amount, data);
        _totalSupplyOf[id] = _totalSupplyOf[id].add(amount);
        require(
            _maxSupplyOf[id] == 0 || _totalSupplyOf[id] <= _maxSupplyOf[id],
            "Exceeds the max supply. Set a new max supply value."
        );
    }

    function _burn(
        address account,
        uint256 id,
        uint256 amount
    ) internal override {
        super._burn(account, id, amount);
        _totalSupplyOf[id] = _totalSupplyOf[id].sub(amount);
    }

    function _beforeTokenTransfer(
        address,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory,
        bytes memory
    ) internal override {
        if (from == address(0) || to == address(0)) {
            // contribution can be minted or burned before the dao launch
        } else {
            // transfer is only allowed after the finalization
            for (uint256 i = 0; i < ids.length; i++) {
                require(_finalized[ids[i]], "Not finalized");
            }
        }
    }

    function _initialContributorShareProgram(uint256 projId)
        internal
        view
        returns (bool)
    {
        return _minimumShare[projId] != 0;
    }
}