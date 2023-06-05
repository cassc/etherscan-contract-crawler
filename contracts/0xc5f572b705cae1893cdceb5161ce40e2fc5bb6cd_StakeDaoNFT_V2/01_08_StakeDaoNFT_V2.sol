//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;
import "@openzeppelin/contracts/ownership/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/GSN/Context.sol";
import "./ERC1155Tradable.sol";

/**
 * @title StrategyRole
 * @dev Owner is responsible to add/remove strategy
 */
contract StrategyRole is Context, Ownable {
    using Roles for Roles.Role;

    event StrategyAdded(address indexed account);
    event StrategyRemoved(address indexed account);

    Roles.Role private _strategies;

    modifier onlyStrategy() {
        require(
            isStrategy(_msgSender()),
            "StrategyRole: caller does not have the Strategy role"
        );
        _;
    }

    function isStrategy(address account) public view returns (bool) {
        return _strategies.has(account);
    }

    function addStrategy(address account) public onlyOwner {
        _addStrategy(account);
    }

    function removeStrategy(address account) public onlyOwner {
        _removeStrategy(account);
    }

    function _addStrategy(address account) internal {
        _strategies.add(account);
        emit StrategyAdded(account);
    }

    function _removeStrategy(address account) internal {
        _strategies.remove(account);
        emit StrategyRemoved(account);
    }
}

/**
 * @title Strategy Access NFT Contract for StakeDAO
 * @dev The contract keeps a count of NFTs being used in some strategy for
 *      for each user and allows transfers based on that.
 */
contract StakeDaoNFT_V2 is ERC1155Tradable, StrategyRole {
    using SafeMath for uint256;

    event StartedUsingNFT(
        address indexed account,
        uint256 indexed id,
        address indexed strategy
    );
    event EndedUsingNFT(
        address indexed account,
        uint256 indexed id,
        address indexed strategy
    );

    // mapping account => nftId => useCount
    // this is used to restrict transfers if nft is being used in any strategy
    mapping(address => mapping(uint256 => uint256)) internal totalUseCount;

    // mapping account => nftId => strategyAddress => useCount
    // this is used to make sure a strategy can only end using nft that it started using before
    mapping(address => mapping(uint256 => mapping(address => uint256)))
        internal stratUseCount;

    // TODO: proper name, metadata uri
    constructor(address _proxyRegistryAddress)
        public
        ERC1155Tradable("Stake DAO NFT", "sdNFT", _proxyRegistryAddress)
    {
        _setBaseMetadataURI(
            "https://gateway.pinata.cloud/ipfs/QmS2txkRpQUX3XhMHjYNem8iCoPhPekYcjbwamT2NDCkH1/metadata/"
        );

        // starting ids for these nfts from 223
        // since 222 nfts (tempest, pythia) have been minted using old implementation
        _currentTokenID = 222;
    }

    function contractURI() public view returns (string memory) {
        return
            "https://gateway.pinata.cloud/ipfs/Qmc1i37KPdg7Cp8rzjgp3QoCECaEbfoSymCpKG8hF85ENv";
    }

    function getTotalUseCount(address _account, uint256 _id)
        public
        view
        returns (uint256)
    {
        return totalUseCount[_account][_id];
    }

    function getStratUseCount(
        address _account,
        uint256 _id,
        address _strategy
    ) public view returns (uint256) {
        return stratUseCount[_account][_id][_strategy];
    }

    /**
     * @notice Mark NFT as being used. Only callable by registered strategies
     * @param _account  User account address
     * @param _id       ID of the token type
     */
    function startUsingNFT(address _account, uint256 _id) public onlyStrategy {
        require(
            balances[_account][_id] > 0,
            "StakeDaoNFT_V2: user account doesnt have NFT"
        );
        stratUseCount[_account][_id][msg.sender] = stratUseCount[_account][_id][
            msg.sender
        ].add(1);
        totalUseCount[_account][_id] = totalUseCount[_account][_id].add(1);
        emit StartedUsingNFT(_account, _id, msg.sender);
    }

    /**
     * @notice Unmark NFT as being used. Only callable by registered strategies
     * @param _account  User account address
     * @param _id       ID of the token type
     */
    function endUsingNFT(address _account, uint256 _id) public onlyStrategy {
        // if a strategy tries to call endUsingNFT function for which it did not call
        // startUsingNFT then subtraction reverts due to safemath.
        stratUseCount[_account][_id][msg.sender] = stratUseCount[_account][_id][
            msg.sender
        ].sub(1);
        totalUseCount[_account][_id] = totalUseCount[_account][_id].sub(1);
        emit EndedUsingNFT(_account, _id, msg.sender);
    }

    /**
     * @dev Overrides safeTransferFrom function of ERC1155 to introduce totalUseCount check
     */
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _id,
        uint256 _amount,
        bytes memory _data
    ) public {
        // check if nft is being used
        require(
            totalUseCount[_from][_id] == 0,
            "StakeDaoNFT_V2: NFT being used in strategy"
        );
        super.safeTransferFrom(_from, _to, _id, _amount, _data);
    }

    /**
     * @dev Overrides safeBatchTransferFrom function of ERC1155 to introduce totalUseCount check
     */
    function safeBatchTransferFrom(
        address _from,
        address _to,
        uint256[] memory _ids,
        uint256[] memory _amounts,
        bytes memory _data
    ) public {
        // Number of transfer to execute
        uint256 nTransfer = _ids.length;

        // check if any nft is being used
        for (uint256 i = 0; i < nTransfer; i++) {
            require(
                totalUseCount[_from][_ids[i]] == 0,
                "StakeDaoNFT_V2: NFT being used in strategy"
            );
        }

        super.safeBatchTransferFrom(_from, _to, _ids, _amounts, _data);
    }

    function burn(
        address _from,
        uint256 _id,
        uint256 _amount
    ) public onlyOwner {
        // check if nft is being used
        require(
            totalUseCount[_from][_id] == 0,
            "StakeDaoNFT_V2: NFT being used in strategy"
        );
        super.burn(_from, _id, _amount);
    }
}