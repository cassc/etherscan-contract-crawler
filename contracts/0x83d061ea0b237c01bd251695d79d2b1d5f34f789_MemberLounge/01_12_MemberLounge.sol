// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

//-----------------------------------------------------------------------------
// geneticchain.io - NextGen Generative NFT Platform
//-----------------------------------------------------------------------------
 /*\_____________________________________________________________   .¿yy¿.   __
 MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM```````/MMM\\\\\  \\$$$$$$S/  .
 MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM``   `/  yyyy    ` _____J$$$^^^^/%#//
 MMMMMMMMMMMMMMMMMMMYYYMMM````      `\/  .¿yü  /  $ùpüüü%%% | ``|//|` __
 MMMMMYYYYMMMMMMM/`     `| ___.¿yüy¿.  .d$$$$  /  $$$$SSSSM |   | ||  MMNNNNNNM
 M/``      ``\/`  .¿ù%%/.  |.d$$$$$$$b.$$$*°^  /  o$$$  __  |   | ||  MMMMMMMMM
 M   .¿yy¿.     .dX$$$$$$7.|$$$$"^"$$$$$$o`  /MM  o$$$  MM  |   | ||  MMYYYYYYM
   \\$$$$$$S/  .S$$o"^"4$$$$$$$` _ `SSSSS\        ____  MM  |___|_||  MM  ____
  J$$$^^^^/%#//oSSS`    YSSSSSS  /  pyyyüüü%%%XXXÙ$$$$  MM  pyyyyyyy, `` ,$$$o
 .$$$` ___     pyyyyyyyyyyyy//+  /  $$$$$$SSSSSSSÙM$$$. `` .S&&T$T$$$byyd$$$$\
 \$$7  ``     //o$$SSXMMSSSS  |  /  $$/&&X  _  ___ %$$$byyd$$$X\$`/S$$$$$$$S\
 o$$l   .\\YS$$X>$X  _  ___|  |  /  $$/%$$b.,.d$$$\`7$$$$$$$$7`.$   `"***"`  __
 o$$l  __  7$$$X>$$b.,.d$$$\  |  /  $$.`7$$$$$$$$%`  `*+SX+*|_\\$  /.     ..\MM
 o$$L  MM  !$$$$\$$$$$$$$$%|__|  /  $$// `*+XX*\'`  `____           ` `/MMMMMMM
 /$$X, `` ,S$$$$\ `*+XX*\'`____  /  %SXX .      .,   NERV   ___.¿yüy¿.   /MMMMM
  7$$$byyd$$$>$X\  .,,_    $$$$  `    ___ .y%%ü¿.  _______  $.d$$$$$$$S.  `MMMM
  `/S$$$$$$$\\$J`.\\$$$ :  $\`.¿yüy¿. `\\  $$$$$$S.//XXSSo  $$$$$"^"$$$$.  /MMM
 y   `"**"`"Xo$7J$$$$$\    $.d$$$$$$$b.    ^``/$$$$.`$$$$o  $$$$\ _ 'SSSo  /MMM
 M/.__   .,\Y$$$\\$$O` _/  $d$$$*°\ pyyyüüü%%%W $$$o.$$$$/  S$$$. `  S$To   MMM
 MMMM`  \$P*$$X+ b$$l  MM  $$$$` _  $$$$$$SSSSM $$$X.$T&&X  o$$$. `  S$To   MMM
 MMMX`  $<.\X\` -X$$l  MM  $$$$  /  $$/&&X      X$$$/$/X$$dyS$$>. `  S$X%/  `MM
 MMMM/   `"`  . -$$$l  MM  yyyy  /  $$/%$$b.__.d$$$$/$.'7$$$$$$$. `  %SXXX.  MM
 MMMMM//   ./M  .<$$S, `` ,S$$>  /  $$.`7$$$$$$$$$$$/S//_'*+%%XX\ `._       /MM
 MMMMMMMMMMMMM\  /$$$$byyd$$$$\  /  $$// `*+XX+*XXXX      ,.      .\MMMMMMMMMMM
 GENETIC/MMMMM\.  /$$$$$$$$$$\|  /  %SXX  ,_  .      .\MMMMMMMMMMMMMMMMMMMMMMMM
 CHAIN/MMMMMMMM/__  `*+YY+*`_\|  /_______//MMMMMMMMMMMMMMMMMMMMMMMMMMM/-/-/-\*/
//-----------------------------------------------------------------------------
// Genetic Chain: Member Lounge
//-----------------------------------------------------------------------------
// Author: papaver (@tronicdreams)
//-----------------------------------------------------------------------------

import "openzeppelin-solidity/contracts/access/Ownable.sol";
import "openzeppelin-solidity/contracts/token/ERC721/IERC721.sol";
import "openzeppelin-solidity/contracts/token/ERC721/IERC721Receiver.sol";
import "openzeppelin-solidity/contracts/token/ERC1155/ERC1155.sol";

//------------------------------------------------------------------------------
// GeneticChainMetadata
//------------------------------------------------------------------------------

/**
 * @title GeneticChain - MemberLounge
 */
contract MemberLounge is ERC1155, IERC721Receiver,
    Ownable
{

    //-------------------------------------------------------------------------
    // structs
    //-------------------------------------------------------------------------

    struct Token {
        uint16 passList;
        uint56 maxSupply;
        uint56 totalSupply;
        int64 minStakeTime;
        int64 createdTS;
    }

    struct Pass {
        uint8 passId;
        uint16 tokenId;
        int64 stakedTS;
    }

    //-------------------------------------------------------------------------
    // events
    //-------------------------------------------------------------------------

    /**
     * Emited when a new token is created.
     */
    event TokenCreated(uint256 tokenId, uint16 passList, uint56 maxSupply,
        int64 minStakeTime, int64 createdTS);

    /**
     * Emited when a new pass is staked.
     */
    event Staked(address indexed owner, address pass, uint256 tokenId, int64 stakedTS);

    /**
     * Emited when a new pass is staked.
     */
    event Unstaked(address indexed owner, address pass, uint256 tokenId);

    /**
     * Emited when a reward is claimed.
     */
    event RewardsClaimed(address indexed owner, uint256 tokenId, uint256 amount);

    //-------------------------------------------------------------------------
    // constants
    //-------------------------------------------------------------------------

    address constant kDeadAddy = 0x000000000000000000000000000000000000dEaD;

    // token name/symbol
    string constant private _name   = "Genetic Chain Member Lounge";
    string constant private _symbol = "GCML";

    // contract info
    string public _contractUri;

    //-------------------------------------------------------------------------
    // fields
    //-------------------------------------------------------------------------

    // track tokens
    Token[] private _tokens;

    // handle token uri overrides
    mapping (uint256 => string) private _ipfsHash;

    // roles
    mapping (address => bool) private _minterAddress;
    mapping (address => bool) private _burnerAddress;

    // staking
    IERC721[] private _passes;
    mapping (address => uint8) private _passIdx;
    mapping (address => Pass[]) private _stakedPasses;

    // claim
    mapping (uint256 => bool) private _claims;

    //-------------------------------------------------------------------------
    // ctor
    //-------------------------------------------------------------------------

    constructor(
        string memory baseUri,
        string memory contractUri,
        address[] memory passes)
        ERC1155(baseUri)
    {
        // start token index at 1
        _tokens.push();

        // start pass index at 1 else we can't use 0 index to indicate
        //  an invalid pass inside _passIdx
        _passes.push();

        // save contract uri
        _contractUri = contractUri;

        // register passes
        for (uint256 i = 0; i < passes.length; ++i) {
            _registerPassContract(passes[i]);
        }
    }

    //-------------------------------------------------------------------------
    // modifiers
    //-------------------------------------------------------------------------

    modifier validTokenId(uint256 tokenId) {
        require(_created(tokenId), "invalid token");
        _;
    }

    //-------------------------------------------------------------------------

	/**
     * Verify caller is authorized minter.
     */
    modifier isMinter() {
        require(_minterAddress[_msgSender()] || owner() == _msgSender(), "caller not minter");
        _;
    }

    //-------------------------------------------------------------------------

	/**
     * Verify caller is authorized burner.
     */
    modifier isBurner() {
        require(_burnerAddress[_msgSender()], "caller not burner");
        _;
    }

    //-------------------------------------------------------------------------
    // internal
    //-------------------------------------------------------------------------

    /**
     * @dev Returns whether the specified token was created.
     */
    function _created(uint256 id)
        internal view
        returns (bool)
    {
        return id < _tokens.length && _tokens[id].createdTS > 0;
    }

    //-------------------------------------------------------------------------

    /**
     * @dev Returns whether the specified token has supply.
     */
    function _exists(uint256 id)
        internal view
        returns (bool)
    {
        return id < _tokens.length && _tokens[id].totalSupply > 0;
    }

    //-------------------------------------------------------------------------

    function _registerPassContract(address pass)
        internal
    {
        require(IERC165(pass).supportsInterface(type(IERC721).interfaceId), "not IERC721 compliant");
        _passIdx[pass] = uint8(_passes.length);
        _passes.push(IERC721(pass));
    }

    //-------------------------------------------------------------------------

    function _mkClaimId(address claimee, uint256 tokenId)
        internal pure
        returns(uint256)
    {
        return uint256(uint160(claimee)) << 96 | tokenId;
    }

    //-------------------------------------------------------------------------

    function _inPassList(uint8 passId, uint16 passList)
        internal pure
        returns(bool)
    {
        return passList & uint16(1 << (passId - 1)) != 0;
    }

    //-------------------------------------------------------------------------

    function _calculateRewards(address claimee, uint256 tokenId)
        internal view
        returns(uint256 rewards)
    {
        // token to calculate rewards for
        Token storage token = _tokens[tokenId];

        // claim rewards for passes staked long enough
        uint256 stakedCount = _stakedPasses[claimee].length;
        for (uint256 i = 0; i < stakedCount; ++i) {
            Pass storage stakedPass = _stakedPasses[claimee][i];
            int64 timeElapsed = token.createdTS - stakedPass.stakedTS;
            if (timeElapsed >= token.minStakeTime
                && _inPassList(stakedPass.passId, token.passList))
            {
                rewards += 1;
            }
        }
    }

    //-------------------------------------------------------------------------
    // ERC165
    //-------------------------------------------------------------------------

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public view virtual override(ERC1155)
        returns (bool)
    {
        return interfaceId == type(IERC721Receiver).interfaceId
            || super.supportsInterface(interfaceId);
    }

    //-------------------------------------------------------------------------
    // ERC1155
    //-------------------------------------------------------------------------

    /**
     * @dev See {ERC1155-_mint}.
     */
    function _mint(
            address account, uint256 id, uint256 amount, bytes memory data)
        internal virtual override validTokenId(id)
    {
        super._mint(account, id, amount, data);
        _tokens[id].totalSupply += uint56(amount);
        require(_tokens[id].totalSupply <= _tokens[id].maxSupply,
            'amount exceed maxsupply');
    }

    //-------------------------------------------------------------------------

    /**
     * @dev See {ERC1155-_mintBatch}.
     */
    function _mintBatch(
            address to, uint256[] memory ids, uint256[] memory amounts,
            bytes memory data)
        internal virtual override
    {
        super._mintBatch(to, ids, amounts, data);

        unchecked {
            for (uint256 i = 0; i < ids.length; ++i) {
                uint256 id = ids[i];
                require(_created(id), 'invalid token');
                _tokens[id].totalSupply += uint56(amounts[i]);
                require(_tokens[id].totalSupply <= _tokens[id].maxSupply,
                    'amount exceed maxsupply');
            }
        }
    }

    //-------------------------------------------------------------------------

    /**
     * @dev See {ERC1155-_burn}.
     */
    function _burn(address account, uint256 id, uint256 amount)
        internal virtual override validTokenId(id)
    {
        super._burn(account, id, amount);

        unchecked {
            _tokens[id].totalSupply -= uint56(amount);
        }
    }

    //-------------------------------------------------------------------------

    /**
     * @dev See {ERC1155-_burnBatch}.
     */
    function _burnBatch(
            address account, uint256[] memory ids, uint256[] memory amounts)
        internal virtual override
    {
        super._burnBatch(account, ids, amounts);

        unchecked {
            for (uint256 i = 0; i < ids.length; ++i) {
                uint256 id = ids[i];
                _tokens[id].totalSupply -= uint56(amounts[i]);
            }
        }
    }

    //-------------------------------------------------------------------------

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     *  Each token should have it's own override.
     */
    function uri(uint256 id)
        public view override validTokenId(id)
        returns (string memory)
    {
        // append hash or use base
        return bytes(_ipfsHash[id]).length == 0
            ? super.uri(id)
            : string(abi.encodePacked(super.uri(id), "/", _ipfsHash[id]));
    }

    //-------------------------------------------------------------------------
    // admin
    //-------------------------------------------------------------------------

    /**
     * Authorize minter address.
     */
    function registerMinterAddress(address minter)
        public onlyOwner
    {
        require(!_minterAddress[minter], "address already registered");
        _minterAddress[minter] = true;
    }

    //-------------------------------------------------------------------------

    /**
     * Remove minter address.
     */
    function revokeMinterAddress(address minter)
        public onlyOwner
    {
        require(_minterAddress[minter], "address not registered");
        delete _minterAddress[minter];
    }

    //-------------------------------------------------------------------------

    /**
     * Authorize burner address.
     */
    function registerBurnerAddress(address burner)
        public onlyOwner
    {
        require(!_burnerAddress[burner], "address already registered");
        _burnerAddress[burner] = true;
    }

    //-------------------------------------------------------------------------

    /**
     * Remove burner address.
     */
    function revokeBurnerAddress(address burner)
        public onlyOwner
    {
        require(_burnerAddress[burner], "address not registered");
        delete _burnerAddress[burner];
    }

    //-------------------------------------------------------------------------

    /**
     * @dev Update default tokenUri used for all tokens.
     *
     * Should use the `\{id\}` replace mechanism to load the token id.
     */
    function setURI(string memory tokenUri)
        public onlyOwner
    {
        _setURI(tokenUri);
        emit URI(tokenUri, 0);
    }

    //-------------------------------------------------------------------------

    /**
     * @dev Override token's ipfs hash.
     */
    function setTokenIpfsHash(uint256 id, string memory ipfsHash)
        public onlyOwner validTokenId(id)
    {
        _ipfsHash[id] = ipfsHash;
        emit URI(uri(id), id);
    }

    //-------------------------------------------------------------------------

    /**
     * @dev Override token's pass list.
     */
    function setTokenPassList(uint256 id, uint16 passList)
        public onlyOwner validTokenId(id)
    {
        _tokens[id].passList = passList;
    }

    //-------------------------------------------------------------------------

    /**
     * @dev Override token's max supply.
     */
    function setTokenMaxSupply(uint256 id, uint56 maxSupply)
        public onlyOwner validTokenId(id)
    {
        require(maxSupply >= _tokens[id].totalSupply, 'max must exceed total');
        _tokens[id].maxSupply = maxSupply;
    }

    //-------------------------------------------------------------------------

    /**
     * @dev Override token's minimum stake time.
     */
    function setTokenMinStakeTime(uint256 id, int64 minStakeTime)
        public onlyOwner validTokenId(id)
    {
        _tokens[id].minStakeTime = minStakeTime;
    }

    //-------------------------------------------------------------------------

    /**
     * @dev Override token's minimum stake time.
     */
    function editToken(uint256 id, uint16 passList, uint56 maxSupply,
            int64 minStakeTime, string memory ipfsHash)
        public onlyOwner validTokenId(id)
    {
        require(maxSupply >= _tokens[id].totalSupply, 'max must exceed total');
        _tokens[id].passList     = passList;
        _tokens[id].maxSupply    = maxSupply;
        _tokens[id].minStakeTime = minStakeTime;

        _ipfsHash[id] = ipfsHash;
        emit URI(uri(id), id);
    }

    //-------------------------------------------------------------------------

    /**
     * @dev Create a new token.
     * @param passList uint16 Passes eligible for reward.
     * @param amount uint256 Mint amount tokens to caller.
     * @param minStakeTime int64 Minimum time pass stake required to qualify
     * @param maxSupply uint56 Max mintable supply for this token.
     * @param ipfsHash string Override ipfsHash for newly created token.
     */
    function create(uint16 passList, uint256 amount, uint56 maxSupply,
            int64 minStakeTime, string memory ipfsHash)
        public onlyOwner
    {
        require(amount > 0, 'invalid amount');
        require(bytes(ipfsHash).length > 0, 'invalid ipfshash');

        // grab token id
        uint256 tokenId = _tokens.length;

        // add token
        int64 createdAt    = int64(int256(block.timestamp));
        Token memory token = Token(passList, maxSupply, 0, minStakeTime, createdAt);
        _tokens.push(token);

        // override token's ipfsHash
        _ipfsHash[tokenId] = ipfsHash;
        emit URI(uri(tokenId), tokenId);

        // mint a single token
        _mint(msg.sender, tokenId, amount, "");

        // created event
        emit TokenCreated(tokenId, passList, maxSupply, minStakeTime, createdAt);
    }

    //-------------------------------------------------------------------------

    function mint(address to, uint256 id, uint256 amount)
        public isMinter
    {
        require(amount > 0, 'invalid amount');
        _mint(to, id, amount, "");
    }

    //-------------------------------------------------------------------------

    function mintBatch(address to,
            uint256[] calldata ids, uint256[] calldata amounts)
        external isMinter
    {
        _mintBatch(to, ids, amounts, "");
    }

    //-------------------------------------------------------------------------

    function burn(address to, uint256 id, uint256 amount)
        public isBurner
    {
        require(amount > 0, 'invalid amount');
        _burn(to, id, amount);
    }

    //-------------------------------------------------------------------------

    function burnBatch(address to,
            uint256[] calldata ids, uint256[] calldata amounts)
        external isBurner
    {
        _burnBatch(to, ids, amounts);
    }

    //-------------------------------------------------------------------------
    // accessors
    //-------------------------------------------------------------------------

    /**
     * @dev Conform to {IERC721Metadata-name}.
     */
    function name()
        public pure
        returns (string memory)
    {
        return _name;
    }

    //-------------------------------------------------------------------------

    /**
     * @dev Conform to {IERC721Metadata-symbol}.
     */
    function symbol()
        public pure
        returns (string memory)
    {
        return _symbol;
    }

    //-------------------------------------------------------------------------

    /**
     * @dev Total amount of tokens in with a given id.
     */
    function totalSupply(uint256 id)
        public view
        returns (uint256)
    {
        return id < _tokens.length
            ? _tokens[id].totalSupply
            : 0;
    }

    //-------------------------------------------------------------------------
    // IERC721Receiver
    //-------------------------------------------------------------------------

    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     */
    function onERC721Received(
            address, address, uint256, bytes calldata)
        public pure override
        returns (bytes4)
    {
        return this.onERC721Received.selector ^ 0x23b872dd;
    }

    //-------------------------------------------------------------------------
    // interface
    //-------------------------------------------------------------------------

    /**
     * @dev Return token info.
     */
    function getToken(uint256 id)
        public view validTokenId(id)
        returns (Token memory, string memory)
    {
        return (_tokens[id], _ipfsHash[id]);
    }

    //-------------------------------------------------------------------------

    /**
     * @dev Return list of all tokens.
     */
    function allTokens()
        public view
        returns (Token[] memory)
    {
        // return empty so all token indecies line up
        return _tokens;
    }

    //-------------------------------------------------------------------------

    /**
     * @dev Return list of pass contracts.
     */
    function allPassContracts()
        public view
        returns (address[] memory)
    {
        // keep the first empty entry so index lines up with id
        uint256 count = _passes.length;
        address[] memory passes = new address[](count);
        for (uint256 i = 0; i < count; ++i) {
            passes[i] = address(_passes[i]);
        }
        return passes;
    }

    //-------------------------------------------------------------------------

    /**
     * @dev Return list of passes staked by staker.
     */
    function getStakedPasses(address staker)
        public view
        returns (Pass[] memory stakedPasses)
    {
        stakedPasses = _stakedPasses[staker];
    }

    //-------------------------------------------------------------------------

    /**
     * @dev Query pass for owners balance.
     */
    function balanceOfPass(address pass, address owner)
        public
        view
        returns (uint256)
    {
        require(_passIdx[pass] != 0, 'invalid pass address');

        // grab pass
        uint8 passId    = _passIdx[pass];
        IERC721 pass721 = _passes[passId];

        // return pass balance
        return pass721.balanceOf(owner);
    }

    //-------------------------------------------------------------------------

    /**
     * @dev Stake single pass.
     */
    function stakePass(address pass, uint256 tokenId)
        public
    {
        require(_passIdx[pass] != 0, 'invalid pass address');

        address sender = _msgSender();

        // grab pass
        uint8 passId    = _passIdx[pass];
        IERC721 pass721 = _passes[passId];

        // verify ownership
        require(pass721.ownerOf(tokenId) == sender, 'not pass owner');

        // transfer here
        pass721.transferFrom(sender, address(this), tokenId);

        // save staked info
        int64 stakedTS = int64(int256(block.timestamp));
        Pass memory stakedPass = Pass(
            passId,
            uint16(tokenId),
            stakedTS);
        _stakedPasses[sender].push(stakedPass);

        // track skate event
        emit Staked(sender, pass, tokenId, stakedTS);
    }

    //-------------------------------------------------------------------------

    /**
     * @dev Unstake single pass.
     */
    function unstakePass(address pass, uint256 tokenId)
        public
    {
        require(_passIdx[pass] != 0, 'invalid pass address');

        address sender = _msgSender();

        // grab pass
        uint8 passId    = _passIdx[pass];
        IERC721 pass721 = _passes[passId];

        // find pass
        uint256 stakedCount = _stakedPasses[sender].length;
        for (uint256 i = 0; i < stakedCount; ++i) {
            Pass storage stakedPass = _stakedPasses[sender][i];
            if (stakedPass.passId == passId && stakedPass.tokenId == tokenId) {

                // transfer pass back to owner
                pass721.transferFrom(address(this), sender, tokenId);

                // keep array compact
                uint256 lastIndex = stakedCount - 1;
                if (i != lastIndex) {
                    _stakedPasses[sender][i] = _stakedPasses[sender][lastIndex];
                }

                // cleanup
                _stakedPasses[sender].pop();

                // track unskate event
                emit Unstaked(sender, pass, tokenId);

                // no need to continue
                return;
            }
        }

        // invalid pass
        require(false, 'pass not found');
    }

    //-------------------------------------------------------------------------

    /**
     * @dev Unstake all passes staked in contract.
     */
    function unstakeAllPasses()
        public
    {
        address sender = _msgSender();
        require(_stakedPasses[sender].length > 0, 'no passes staked');

        // unstake all passes
        uint256 stakedCount = _stakedPasses[sender].length;
        for (uint256 i = 0; i < stakedCount; ++i) {
            Pass storage stakedPass = _stakedPasses[sender][i];
            IERC721 pass721         = _passes[stakedPass.passId];

            // transfer pass back to owner
            pass721.transferFrom(address(this), sender, stakedPass.tokenId);

            // track unskate event
            emit Unstaked(sender, address(pass721), stakedPass.tokenId);

            // cleanup
            delete _stakedPasses[sender][i];
        }

        // cleanup
        delete _stakedPasses[sender];
    }

    //-------------------------------------------------------------------------

    /**
     * Calculate rewards available for user for given tokenId.
     */
    function calculateRewards(uint256 tokenId, address user)
        public view validTokenId(tokenId)
        returns(uint256)
    {
        uint256 claimId = _mkClaimId(user, tokenId);
        return _claims[claimId]
            ? 0
            : _calculateRewards(user, tokenId);
    }

    //-------------------------------------------------------------------------

    function calculateRewardsBatch(uint256[] memory tokenIds, address user)
        public view
        returns(uint256[] memory)
    {
        uint256 count = tokenIds.length;
        uint256[] memory rewards = new uint256[](count);
        for (uint256 i = 0; i < count; ++i) {
            rewards[i] = calculateRewards(tokenIds[i], user);
        }
        return rewards;
    }

    //-------------------------------------------------------------------------

    /**
     * @dev Claim single token for all passes.
     */
    function claim(uint256 tokenId)
        public validTokenId(tokenId)
    {
        address sender = _msgSender();
        require(_stakedPasses[sender].length > 0, 'no passes staked');

        // check claim
        uint256 claimId = _mkClaimId(sender, tokenId);
        require(!_claims[claimId], 'rewards claimed');

        // process all passes
        uint256 rewards = _calculateRewards(sender, tokenId);
        require(rewards > 0, 'no rewards');

        // mark as claimed
        _claims[claimId] = true;

        // mint token for claimee
        _mint(sender, tokenId, rewards, "");

        // record event
        emit RewardsClaimed(sender, tokenId, rewards);
    }

    //-------------------------------------------------------------------------

    /**
     * @dev Claim multiple tokens at once.
     */
    function claimBatch(uint256[] calldata tokenIds)
        public
    {
        require(tokenIds.length > 0, 'no token ids');
        uint256 tokenCount = tokenIds.length;
        for (uint256 i = 0; i < tokenCount; ++i) {
            claim(tokenIds[i]);
        }
    }

    //-------------------------------------------------------------------------

    function setContractURI(string memory contractUri)
        external onlyOwner
    {
        _contractUri = contractUri;
    }

    //-------------------------------------------------------------------------

    function contractURI()
        public view
        returns (string memory)
    {
        return _contractUri;
    }

}