pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT

/**
 *
 * This contract is a part of the House of Panda project.
 *
 * House of Panda is an NFT-based real estate investment platform that gives you access to high-yield, short-term loans.
 * This contract is built with BlackRoof engine.
 *
 */

import "SafeERC20.sol";

import "ICoin.sol";
import "ProjectInfo.sol";
import "HoldingInfo.sol";
import "StakeInfo.sol";
import "HasAdmin.sol";
import "SigVerifier.sol";
import "Staker.sol";

contract HouseOfPanda is
    ERC1155Tradable,
    IProjectMan,
    HasAdmin,
    SigVerifier,
    ReentrancyGuard
{
    using SafeERC20 for ICoin;
    using Strings for uint256;

    ICoin internal stableCoin;
    uint32 public projectIndex;
    IStaker public staker;

    mapping(uint32 => uint128) private _supplyFor;

    bool public paused = false;

    event ProjectCreated(uint32 indexed id);
    event ProjectStatusChanged(uint32 indexed projectId, bytes1 indexed status);
    event Mint(
        uint32 indexed projectId,
        uint128 indexed qty,
        address minter,
        address indexed to
    );
    event Burn(
        uint32 indexed projectId,
        uint128 indexed qty,
        address indexed burner
    );

    /**
     * Constructor for the HouseOfPanda contract, which inherits from the
     * ERC1155Tradable and Stake contracts.
     * Set the contract's base URI and proxy address and set the admin address.
     *
     * @param _admin The contract's admin address.
     * @param _baseUri The contract's base URI.
     * @param _stableCoin The address of the stablecoin for calculating rewards.
     * @param _proxyAddress The address of the proxy contract.
     */
    constructor(
        address _admin,
        string memory _baseUri,
        address _stableCoin,
        IStaker _staker,
        address _proxyAddress
    ) ERC1155Tradable("House of Panda", "HOPNFT", _baseUri, _proxyAddress) {
        _staker.setProjectMan(address(this));
        staker = _staker;
        stableCoin = ICoin(_stableCoin);
        _setAdmin(_admin);
    }

    function changeAdmin(address newAdmin_) external onlyOwner {
        _setAdmin(newAdmin_);
    }

    modifier onlyAdminOrOwner() {
        require(_isAdmin(msg.sender) || _isOwner(msg.sender), "!admin !owner");
        _;
    }

    /**
     * This function checks if the parameter 'account' is the owner of the contract.
     * @param account The address of the account to be checked.
     * @return {bool} A boolean indicating whether the account is the owner or not.
     */
    function _isOwner(address account) internal view returns (bool) {
        return owner() == account;
    }

    function min(uint64 a, uint64 b) internal pure returns (uint64) {
        return a <= b ? a : b;
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
    ) internal override {
        if (from == address(0) && to == address(0)) {
            return;
        }

        HoldingInfo memory holding;

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            ProjectInfo memory project = _getProject(uint32(id));

            // cannot be transferred while staking
            StakeInfo memory sti = staker.getStakingInfoRaw(from, uint32(id));
            if (sti.qty > 0) {
                require(balanceOf(from, uint32(id)) - amount >= sti.qty, "in staking");
            }

            uint64 prevStartTime = uint64(block.timestamp);

            if (from != address(0)) {
                holding = staker.getHoldingInfoRaw(from, uint32(id));

                // if already exists, then update holding info
                if (holding.qty > 0) {

                    uint64 endTime = min(uint64(block.timestamp), project.endTime);

                    holding.qty -= amount;
                    if (endTime > holding.startTime) {
                        holding.accumRewards += staker.calculateRewards(
                            holding.qty * project.price,
                            holding.startTime,
                            endTime,
                            project.apy // regular
                        );
                    }
                }

                prevStartTime = holding.startTime;

                holding.startTime = uint64(block.timestamp);

                // update holding info for `from`
                staker.setHoldingInfoData(from, uint32(id), holding);
            }

            if (to != address(0)) {
                // update holding info for `to`
                holding = staker.getHoldingInfoRaw(to, uint32(id));

                uint64 endTime = min(uint64(block.timestamp), project.endTime);

                if (holding.qty > 0 && endTime > holding.startTime) {
                    holding.accumRewards += staker.calculateRewards(
                        holding.qty * project.price,
                        holding.startTime,
                        endTime,
                        project.apy // regular
                    );
                }

                holding.qty += amount;
                holding.startTime = prevStartTime;

                staker.setHoldingInfoData(to, uint32(id), holding);
            }
        }
    }

    /**
     * @dev Creates a new project. This can only be done by the contract admin or owner.
     * @param typeId project type.
     * @param title Title of the project.
     * @param price Price to mint one NFT from this project (in wei). Cannot be zero if `authorizedOnly`=true.
     * @param authorizedOnly If true the project only mintable by admin.
     * @param supplyLimit Supply limit of the project. Minting will fail if max limit.
     * @param term Term of the project in months.
     * @param apy APY of the project.
     * @param stakedApy APY for staked NFT.
     * @param startTime Start time of the project.
     * @param endTime End time of the project.
     */
    function createProject(
        uint16 typeId,
        string memory title,
        uint256 price,
        bool authorizedOnly,
        uint128 supplyLimit,
        uint16 term,
        uint256 apy,
        uint256 stakedApy,
        uint64 startTime,
        uint64 endTime
    ) external onlyAdminOrOwner {
        if (authorizedOnly) {
            require(price > 0, "price=0");
        }
        require(term > 0 && term <= 60, "x term");

        uint32 pid = projectIndex + 1;
        ProjectInfo memory project = ProjectInfo({
            id: pid,
            title: title,
            creator: msg.sender,
            typeId: typeId,
            price: price,
            authorizedOnly: authorizedOnly,
            status: ACTIVE,
            supplyLimit: supplyLimit,
            term: term,
            apy: apy,
            stakedApy: stakedApy,
            startTime: startTime,
            endTime: endTime
        });
        _projects[pid] = project;
        projectIndex = pid;

        emit ProjectCreated(project.id);
    }

    function _exists(uint32 projectId) internal view returns (bool) {
        return _projects[projectId].id == projectId;
    }

    function projectExists(
        uint32 projectId
    ) public view override returns (bool) {
        return _exists(projectId);
    }

    function _getProject(
        uint32 projectId
    ) internal view returns (ProjectInfo memory) {
        require(projectId > 0, "!projectId");
        require(_projects[projectId].id == projectId, "!project");
        return _projects[projectId];
    }

    function getProject(
        uint32 projectId
    ) public view override returns (ProjectInfo memory) {
        return _getProject(projectId);
    }

    /**
     * @dev check is project exists
     */
    function _checkProject(ProjectInfo memory project) internal pure {
        require(project.id > 0, "!project");
    }

    /**
     * This function is used to set the status of a project.
     * The caller of this function must be either the owner or an admin of the
     * contract.
     * It takes in two parameters: the projectId and a bytes1 status.
     * It first checks to make sure the project exists, before setting the status
     * and emitting a ProjectStatusChanged event.
     *
     * @param projectId The ID of the project to set the status for.
     * @param status A bytes1 indicating the new status.
     */
    function setProjectStatus(
        uint32 projectId,
        bytes1 status
    ) external onlyAdminOrOwner {
        require(_exists(projectId), "!project");
        _projects[projectId].status = status;
        emit ProjectStatusChanged(projectId, status);
    }

    /**
     * @dev Mint NFT for specific project. This function demands the exact amount of price,
     *      except for the authorizedOnly project.
     * @param projectId Project id.
     * @param qty Quantity of NFTs to mint.
     */
    function mint(
        uint32 projectId,
        uint32 qty,
        address to
    ) external payable nonReentrant returns (bool) {
        require(!paused, "paused");
        ProjectInfo memory project = _projects[projectId];
        _checkProject(project);
        require(project.status == ACTIVE, "!active");
        require(project.startTime <= block.timestamp, "!start");
        require(project.endTime > block.timestamp, "!ended");

        address _sender = _msgSender();

        bool isAuthority = _isAdmin(_sender) || _isOwner(_sender);

        if (project.authorizedOnly) {
            require(isAuthority, "unauthorized");
        } else {
            require(
                isAuthority ||
                    stableCoin.balanceOf(_sender) >= qty * project.price,
                "balance <"
            );
        }

        // check max supply limit if configured (positive value).
        uint128 supply = _supplyFor[projectId];
        if (project.supplyLimit > 0) {
            require(supply + qty <= project.supplyLimit, "limit");
        }

        _supplyFor[projectId] += qty;

        // deduct stable coin from minter
        if (!project.authorizedOnly && !isAuthority) {
            stableCoin.safeTransferFrom(
                _sender,
                address(staker),
                qty * project.price
            );
        }

        _mint(to, projectId, qty, "");

        emit Mint(projectId, qty, _msgSender(), to);

        return true;
    }

    /**
     * @dev Permissioned version of mint, use signature for verification,
     *      Anyone with valid signature can mint NFTs.
     */
    function authorizedMint(
        uint32 projectId,
        uint32 qty,
        address to,
        uint64 nonce,
        Sig memory sig
    ) external payable nonReentrant returns (bool) {
        require(nonce >= uint64(block.timestamp) / 60, "x nonce");
        _checkAddress(to);

        // require payment
        ProjectInfo memory project = _projects[projectId];
        _checkProject(project);

        // check supply
        uint128 supply = _supplyFor[projectId];
        if (project.supplyLimit > 0) {
            require(supply + qty <= project.supplyLimit, "limit");
        }

        address _sender = _msgSender();

        bytes32 message = sigPrefixed(
            keccak256(abi.encodePacked(projectId, _sender, to, qty, nonce))
        );

        require(_isSigner(admin, message, sig), "x signature");

        bool isAuthority = _isAdmin(_sender) || _isOwner(_sender);

        require(
            isAuthority || stableCoin.balanceOf(_sender) >= qty * project.price,
            "balance <"
        );

        _supplyFor[projectId] += qty;

        // deduct stable coin from minter
        stableCoin.safeTransferFrom(
            _sender,
            address(this),
            qty * project.price
        );

        _mint(to, projectId, qty, "");

        emit Mint(projectId, qty, _sender, to);

        return true;
    }

    /**
     * @dev check supply for specific item.
     */
    function supplyFor(uint32 projectId) external view returns (uint128) {
        return _supplyFor[projectId];
    }

    /**
     * Returns the URI of a given project.
     * If the project has a custom URI (stored in the 'customUri' mapping),
     * the custom URI is returned. Otherwise, the default uri defined in the super
     * class is returned.
     *
     * @param _projectId The ID of the project.
     * @return {string} The URI of the project.
     */
    function uri(
        uint256 _projectId
    ) public view override returns (string memory) {
        require(_exists(uint32(_projectId)), "!project");
        // We have to convert string to bytes to check for existence
        bytes memory customUriBytes = bytes(customUri[_projectId]);
        if (customUriBytes.length > 0) {
            return customUri[_projectId];
        } else {
            // return super.uri(_projectId);
            string memory baseURI = super.uri(_projectId);
            return
                bytes(baseURI).length > 0
                    ? string(
                        abi.encodePacked(
                            baseURI,
                            _projectId.toString(),
                            ".json"
                        )
                    )
                    : "";
        }
    }

    function _checkAddress(address addr) private pure {
        require(addr != address(0), "x addr");
    }

    /**
     * This function is used to pause or unpause contract.
     * Caller of this function must be the owner of the contract.
     * It updates the paused state of the contract and calls the pause function of
     * the staker.
     * @param _paused A boolean indicating whether staking should be paused or
     * unpaused.
     */
    function pause(bool _paused) external onlyOwner {
        paused = _paused;
        staker.pause(_paused);
    }

    function _burnInternal(
        uint32 projectId,
        uint32 qty,
        address to
    ) private returns (bool) {
        _checkAddress(to);
        require(projectId > 0, "!projectId");
        require(qty > 0, "!qty");

        ProjectInfo memory project = _projects[projectId];
        _checkProject(project);

        // check max supply limit if configured (positive value).
        uint128 supply = _supplyFor[projectId];
        require(supply >= qty, "exceed supply");

        // cannot be burned while staking
        StakeInfo memory sti = staker.getStakingInfoRaw(to, projectId);
        if (sti.qty > 0) {
            require(balanceOf(to, projectId) - qty >= sti.qty, "in staking");
        }

        _supplyFor[projectId] -= qty;

        _burn(to, projectId, qty);

        if (project.authorizedOnly) {
            // do nothing
        } else {
            uint256 amount = qty * project.price;
            // payable(to).transfer(amount);
            stableCoin.safeTransferFrom(address(staker), to, amount);
        }

        emit Burn(projectId, qty, to);

        return true;
    }

    /**
     * @dev Burn NFT and claim back the mint price to the NFT owner.
     *      this will emit Burn event when success.
     * @param projectId Project id.
     * @param qty Quantity of NFTs to burn.
     */
    function burn(
        uint32 projectId,
        uint32 qty
    ) external nonReentrant returns (bool) {
        address _sender = _msgSender();
        uint256 _ownedQty = balanceOf(_sender, projectId);
        require(_ownedQty >= qty, "qty >");
        return _burnInternal(projectId, qty, _sender);
    }

    /**
     * @dev Burn NFT by admin and return the mint price to the NFT owner.
     *      Caller of this function must be admin.
     *      this will emit Burn event when success.
     * @param projectId Project id.
     * @param qty Quantity of NFTs to burn.
     * @param to the owner of the NFT to be burned.
     */
    function adminBurn(
        uint32 projectId,
        uint32 qty,
        address to
    ) external payable onlyAdmin nonReentrant returns (bool) {
        return _burnInternal(projectId, qty, to);
    }

    function getHoldingInfo(
        address account,
        uint32 projectId
    ) external view returns (HoldingInfo memory) {
        return staker.getHoldingInfo(account, uint32(projectId));
    }

    /**
     * This function is used to update contract staker.
     * It must be called by the owner of the contract. 
     * It checks that the staker's owner is the same as the contract's owner.
     * @param _staker address of the staker.
     */
    function updateStaker(address _staker) external onlyOwner {
        // check staker owner
        require(IStaker(_staker).owner() == this.owner(), "!owner");
        staker = IStaker(_staker);
    }

    /**
     * This function allows users to retrieve the asset allocation and staking
     * information of the given investor and project ID.
     * It takes in two parameters: 'investor' (the address of the investor) and
     * 'projectId' (the ID of the project).
     * It first checks to make sure the investor address is valid and that a valid
     * project ID was supplied.
     * It then retrieves the holding information and staking information of the
     * respective investor and project,
     * and returns a tuple containing both pieces of information.
     * 
     * @param investor The address of the investor.
     * @param projectId The ID of the project.
     * @return (HoldingInfo memory, StakeInfo memory) A tuple containing the asset
     * allocation and staking information of the investor and project.
     */
    function getAssetAlloc(address investor, uint32 projectId)
        external
        view
        returns (HoldingInfo memory, StakeInfo memory)
    {
        _checkAddress(investor);
        require(projectId > 0, "!projectId");
        HoldingInfo memory hld = staker.getHoldingInfo(investor, projectId);
        StakeInfo memory stk = staker.getStakingInfo(investor, projectId);
        return (hld, stk);
    }
}