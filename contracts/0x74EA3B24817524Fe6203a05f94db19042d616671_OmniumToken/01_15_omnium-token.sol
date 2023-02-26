// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "../omnium-library/contracts/IOmniumStakeableERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";

contract OmniumToken is ERC20Upgradeable, AccessControlUpgradeable {
    using SafeMathUpgradeable for uint256;
    // Event
    event stakeIn (address _contract, address _staker, uint256 tokenId, uint256 _amount);
    event stakeOut (address _contract, address _staker, uint256 tokenId, uint256 _amount);    

    // Constants
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    uint256 private constant MAX_SUPPLY = 80000000 ether;
    uint256 private constant INITIAL_SUPPLY = 14333333 ether;

    // Custom data types
    struct stake {
        uint256 _amount;
        uint256 _stakeInitialTimeStamp;
        uint256 _stakeStartTimeStamp;
        uint256 _accRewards;
    }

    // State Variables    
    bool private _paused;
    mapping ( address => bool ) private _contractsEnabledToStake;
    mapping ( address => mapping ( address => mapping (uint => stake))) private _stakers;        
    mapping ( address => mapping ( address => uint[])) private _stakedIds;
    uint256[49] __gap; //Storage GAP

    function initialize() initializer public {
        __ERC20_init("Omnium Token", "OMTK");     
        __AccessControl_init();           
        _paused = false;
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        // Mints initial amount for owner wallet
        _mint(msg.sender, INITIAL_SUPPLY);
    }

    /**
     * @dev Empty receive function.
     *
     * Requirements:
     *   
     * - Cannot send plain ether to this contract
     */

      receive () external payable { revert(); }

    // EXTERNAL FUNCTIONS

    /**
     * @dev paused: Returns contract pause status
     *   
     */        
    function paused() external view  returns (bool) {
        return _paused;
    }  
   function version() external pure returns (uint) {
        return 1;
    }  
    // PUBLIC FUNCTIONS

    /**
     * @dev Pauses / Resume contract operation.
     *
     */

    function Pause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _paused = !_paused;
    }

    /**
     * @dev Assigns MINTER permission to address
     *
     */
    function setMinterRole( address __account ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(! _paused,"Contract paused");
        _grantRole(MINTER_ROLE, __account);
    }
    /**
     * @dev Remove MINTER permission to address
     *
     */
    function revokeMinterRole( address __account) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(! _paused,"Contract paused");
        _revokeRole(MINTER_ROLE, __account);
    }

    /**
     * @dev allow External ERC1155 contract to stake NFT tokens
     *
     */

    function enableToStake( address __account ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(! _paused,"Contract paused");
        _contractsEnabledToStake[__account] = true;
    }

    /**
     * @dev disable External ERC1155 contract to stake NFT tokens
     *
     */

    function disableToStake( address __account ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(! _paused,"Contract paused");
        require(_contractsEnabledToStake[__account]);

        delete _contractsEnabledToStake[__account];
    }

    /**
     * @dev Mints tokens 
     *
     * Requirements:
     *   
     */

    function mint(address __to, uint256 __amount) public onlyRole(MINTER_ROLE) {
        require(!_paused,"Contract Paused");    
        require(ERC20Upgradeable.totalSupply().add(__amount) <= MAX_SUPPLY,"Max supply reached");

        _mint(__to, __amount);
    }

    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public {
        _burn(_msgSender(), amount);
    }
    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public  {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }

    /**
     * @dev EmptyERC155 Token holder interface implementacion 
     *
     * Requirements:
     *   
     * - Cannot send plain ether to this contract
     */

    function onERC1155Received(
        address,
        address from,
        uint256 id,
        uint256 amount,
        bytes memory
    ) public returns (bytes4) {
        require(!_paused,"Contract Paused");
        require( id > 0,"Invalid token");        
        require(_contractsEnabledToStake[msg.sender],"Invalid Contract");        

        if (_stakers[from][msg.sender][id]._amount == 0) {
            // New stake
            _stakers[from][msg.sender][id]._amount = amount;
            _stakers[from][msg.sender][id]._stakeStartTimeStamp = block.timestamp;      
            _stakers[from][msg.sender][id]._stakeInitialTimeStamp = block.timestamp;      
            _stakers[from][msg.sender][id]._accRewards = 0;    
            _stakedIds[from][msg.sender].push(id);
            // FALTA CODIGO PARA ACTUALIZAR ARRAY DE STAKES
        } else {
            // update previous stake
            _stakers[from][msg.sender][id]._accRewards = _stakers[from][msg.sender][id]._accRewards.add(_getCurrentStakeReward(from,msg.sender,id));
            // Update current stake                  
            _stakers[from][msg.sender][id]._stakeStartTimeStamp =  block.timestamp;
            _stakers[from][msg.sender][id]._amount = _stakers[from][msg.sender][id]._amount.add(amount);
        }

        emit stakeIn (msg.sender, from, id, amount);
        return this.onERC1155Received.selector;
    }

    function getStakes( address _staker, address _contract) public view returns (uint[] memory) {
        return _getStakes(_staker, _contract);
    }

    function getStakeInfo( 
        address _staker, 
        address _contract, 
        uint256 _tokenId
        ) public returns (uint256, uint256, uint256) {
        require( _tokenId > 0,"Invalid token");

        return (_stakers[_staker][_contract][_tokenId]._amount, _stakers[_staker][_contract][_tokenId]._stakeStartTimeStamp,_getTotalStakeReward(_staker,_contract,_tokenId));
    }


    function getStakeReward( 
        address _staker, 
        address _contract, 
        uint256 _tokenId
        ) public returns (uint256) {
        require( _tokenId > 0,"Invalid token");

        return _getTotalStakeReward(_staker,_contract,_tokenId);
    }

     function withdrawRewards( address _sourceContract, uint256 tokenId) public {
        require( tokenId > 0,"Invalid token");        
        _withdrawRewardsFrom(msg.sender, _sourceContract, tokenId);
    }

    function withdrawStake( address _sourceContract, uint256 tokenId) public returns (uint256, uint256) {
        require(!_paused,"Contract Paused");
        require( tokenId > 0,"Invalid token");
        require(_contractsEnabledToStake[_sourceContract],"Invalid Contract");          
        require(_stakers[msg.sender][_sourceContract][tokenId]._amount > 0,"no stake");      
        require(tokenId != 0,"Invalid token");

        address _to = msg.sender;
        uint256 _nfts = 0;
        // withdraw stakerewards
        uint256 _amountRewards = _getTotalStakeReward(_to, _sourceContract, tokenId);
        if ( _amountRewards > 0 ) {
            _withdrawRewardsFrom(_to, _sourceContract, tokenId);
        }
        // withdraw staked nfts
        _nfts = _stakers[_to][_sourceContract][tokenId]._amount;
        delete _stakers[_to][_sourceContract][tokenId]._amount;
        _removeStakeID(_to, _sourceContract, tokenId);               

        // Transfers NFTs to owner
        if (_nfts > 0) {
            try IERC1155Upgradeable(_sourceContract).safeTransferFrom(address(this), _to, tokenId, _nfts, "") {
                emit stakeOut(_sourceContract,_to,tokenId,_nfts);
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("Error during NFT transfer");
            }                                        
        }

        return (_amountRewards, _nfts);
    }

    // INTERNAL FUNCTIONS

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(! _paused,"Contract Paused");

        super._beforeTokenTransfer(from,to,amount);
    }

    function _getCurrentStakeReward( 
        address _staker, 
        address _contract, 
        uint256 _tokenId
        ) internal returns (uint256) {

        require(_contractsEnabledToStake[_contract],"Invalid Contract");                       
        require(_stakers[_staker][_contract][_tokenId]._amount > 0,"No stake");        
        require(_tokenId != 0,"Invalid token");        

        uint256 _stakeReward = 0;
        //86400
        uint256 stakeDays = (block.timestamp.sub(_stakers[_staker][_contract][_tokenId]._stakeStartTimeStamp)).div(86400);
        try IOmniumStakeableERC1155Upgradeable(_contract).getTokenStakeCoeficient(_tokenId) returns( uint256 value ) {
            uint256 tokenCoef = value;
            uint256 stakedAmount = _stakers[_staker][_contract][_tokenId]._amount;
            _stakeReward += stakeDays.mul(tokenCoef).mul(stakedAmount);
        } catch Error(string memory reason) {
            revert(reason);
        } catch {
            revert("Source contract not Omnium Family token");
        }                    

        return _stakeReward;
    }

    function _getTotalStakeReward( 
        address _staker, 
        address _contract, 
        uint256 _tokenId
        ) internal returns (uint256) {

        require(_contractsEnabledToStake[_contract],"Invalid Contract");                       
        require(_stakers[_staker][_contract][_tokenId]._amount > 0,"No stake");        
        require(_tokenId != 0,"Invalid token");        

        uint256 _currentStake = _getCurrentStakeReward(_staker, _contract, _tokenId);

        return _currentStake.add(_stakers[_staker][_contract][_tokenId]._accRewards);
    }


    function _getStakes( address _staker, address _contract ) internal view returns (uint[] memory) {
        return _stakedIds[_staker][_contract];
    }


    // PRIVATE FUNCTIONS

    function _withdrawRewardsFrom( 
        address _staker, 
        address _sourceContract, 
        uint256 tokenId
        ) private {

        require(!_paused,"Contract Paused");
        require(_contractsEnabledToStake[_sourceContract],"Invalid Contract");      
        require(_stakers[_staker][_sourceContract][tokenId]._amount > 0,"no stakes");                                   
        uint256 _withdrawAmount = _getTotalStakeReward(_staker, _sourceContract, tokenId);
        require(_withdrawAmount > 0,"No rewards");
        require(tokenId != 0,"Invalid token");        

        _stakers[_staker][_sourceContract][tokenId]._stakeStartTimeStamp = block.timestamp;
        _stakers[_staker][_sourceContract][tokenId]._accRewards = 0;

        if (ERC20Upgradeable.totalSupply().add(_withdrawAmount) > MAX_SUPPLY) {
            _withdrawAmount = MAX_SUPPLY.sub(ERC20Upgradeable.totalSupply());
        }
        
        _mint(_staker, _withdrawAmount);        
    }

    function _removeStakeID(address _staker, address _contract, uint _id) private  {
        require(_id != 0,"Invalid token");        

        bool _found = false;
        uint _index = 0;
        for (uint i = 0; i<=_stakedIds[_staker][_contract].length-1; i++){
            if (_stakedIds[_staker][_contract][i] == _id) {
                _index = i;
                _found = true;
                break;
            }
        }

        if ( _found ) {
            uint256  _newId = _stakedIds[_staker][_contract].length-1;
            _stakedIds[_staker][_contract][_index] = _stakedIds[_staker][_contract][_newId];
            _stakedIds[_staker][_contract].pop();
        }
        return;
    }
}