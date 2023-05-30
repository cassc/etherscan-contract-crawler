// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

//EtherId Wrapper created to wrap the EtherId Name Registrar created by NAlexandre Averniouk @AlexNa
//
//Written by Callum Quin @callumquin

interface EtherId{
    event DomainChanged( address indexed sender, uint domain, uint id ); // Fired every time the registry is changed
    function getId( uint domain, uint id ) external view returns (uint v, uint next_id, uint prev_id );
    function getDomain( uint domain ) external view returns (address owner, uint expires, uint price, address transfer, uint next_domain, uint root_id );

    function changeDomain( uint domain, uint expires, uint price, address transfer ) external;
    function changeId( uint domain, uint name, uint value ) external;
}

contract EtherIdWrapper is ERC721, Ownable {

    uint constant MAX_PROLONG = 2000000;
    string private baseURI;

    event Wrapped(address indexed owner, uint indexed domain);
    event Unwrapped(address indexed owner, uint indexed domain);


    address public _etherIdAddress;
    EtherId private _etherId;

    constructor(address etherIdAddress) ERC721("Wrapped EtherId", "EID") {
        _etherIdAddress = address(etherIdAddress);
        _etherId = EtherId(_etherIdAddress);
    }

    /**
        Wrapping Functions
    **/
    function wrap(uint domain) external {
        (address owner, uint expires, uint price, address transfer,,) = _etherId.getDomain(domain);

        //Check caller is owner of Domain
        require(_msgSender() == owner, "EtherIdWrapper: You are not the owner of this Domain");

        //Check Domain is not expired
        require(expires > block.number, "EtherIdWrapper: Domain has expired");

        //Check that Domain is transferrable to wrapper contract
        require(transfer == address(this), "EtherIdWrapper: Domain has not been set to Transfer to Wrapper Contract");

        //Check that Price is set to 0
        require(price == 0, "EtherIdWrapper: Price should be set to 0 before wrapping");

        //Transfer Domain to Wrapper Contract
        _etherId.changeDomain(domain, MAX_PROLONG, 0, address(0));

        //Check Transfer was correct
        (address idOwner, uint newExpires, uint newPrice, address newTransfer,,) = _etherId.getDomain(domain);

        require((idOwner == address(this)) && (newExpires > block.number) && (newPrice == 0) && (newTransfer == address(0)), "EtherIdWrapper: Transfering Domain to Wrapper Failed");

        if(_exists(domain)){
            //Domain Allready Wrapped but Expired and New Owner Claimed on Base Contract Now Rewrapping
            address wrappedOwner = ERC721.ownerOf(domain);
            _safeTransfer(wrappedOwner, msg.sender, domain, "");

            //Check transfer of ERC721
            address newOwner = ERC721.ownerOf(domain);
            require(newOwner == msg.sender, "EtherIdWrapper: Error in Transferring Domain");

        }else{
            //Wrapped Domain Does not exist. Mint New ERC721
            _mint(msg.sender, domain);

            address mintOwner = ERC721.ownerOf(domain);
            require(_msgSender() == mintOwner, "EtherIdWrapper: Error Minting ERC721 NFT");
        }

        emit Wrapped(msg.sender, domain);
    }

    function unwrap(uint domain) external {

        //Check NFT Exists
        require(_exists(domain), "EtherIdWrapper: Domain NFT does not exist");
        
        //Check sender is owner of NFT
        address wrappedOwner = ERC721.ownerOf(domain);
        require(wrappedOwner == _msgSender(), "EtherIdWrapper: You are not the owner");

        (address owner, uint expires, uint price, address transfer,,) = _etherId.getDomain(domain);

        //Check Domain is owned by this contract
        require(owner == address(this), "EtherIdWrapper: This domain is not owned by the Wrapper");

        //Check Domain is not expired
        require(expires > block.number, "EtherIdWrapper: Domain has expired");

        //Check Domain has not been listed for sale on base contract (Technically not possible)
        require(price == 0, "EtherIdWrapper: Domain is listed for sale cannot unwrap");

        //Check Domain is not set to be transferred (Also Technically not possible)
        require(transfer == address(0), "EtherIdWrapper: Domain is set for transfer cannot unwrap");

        _etherId.changeDomain(domain, MAX_PROLONG, 0, msg.sender);

        (,,uint newPrice,address newTransfer,,) = _etherId.getDomain(domain);

        require((newPrice == 0) && (newTransfer == msg.sender), "EtherIdWrapper: Domain Info Change Failed");

        _burn(domain);
        require(!_exists(domain), "EtherIDWrapper: ERC721 Domain has not been burned");

        emit Unwrapped(msg.sender, domain);
    }


    /**
        Overriding transfer function to stop expired or switched domains from being transferred (these should be claimed/rewrapped)
    **/
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        (address owner, uint expires, uint price, address transfer,,) = _etherId.getDomain(tokenId);

        //Check Domain is owned by this contract
        require(owner == address(this), "EtherIdWrapper: This domain is not owned by the Wrapper");

        //Check Domain is not expired
        require(expires > block.number, "EtherIdWrapper: Domain has expired");

        //Check Domain has not been listed for sale on base contract (Technically not possible)
        require(price == 0, "EtherIdWrapper: Domain is listed for sale on base contract cannot Transfer");

        //Check Domain is not set to be transferred (Also Techncally not possible)
        require(transfer == address(0), "EtherIdWrapper: Domain is set for transfer on base contract cannot Transfer");

        super._transfer(from, to, tokenId);
    }



    /**
        Write Functions
    **/
    function changeDomain(uint domain) public{
        require( domain != 0, "EtherIdWrapper: Cannot create 0 Domain");

        //Get Domain information from base contract
        (address owner, uint expires, uint price, address transfer,, ) = _etherId.getDomain(domain);

        if(owner == address(0)){
            //Domain does not exist Create New Domain on base Contract and Create ERC721
            _etherId.changeDomain(domain, MAX_PROLONG, 0, address(0));

            (owner ,expires, price, transfer,, ) = _etherId.getDomain(domain);
            //Check Domain is owned by this contract
            require(owner == address(this), "EtherIdWrapper: Error registering this domain to the wrapper");

            //Check Domain is not expired
            require(expires > block.number, "EtherIdWrapper: Domain has expired cannot wrap");

            //Check Domain has not been listed for sale on base contract (Technically not possible)
            require(price == 0, "EtherIdWrapper: Domain is listed for sale cannot wrap");

            //Check Domain is not set to be transferred (Also Techncally not possible)
            require(transfer == address(0), "EtherIdWrapper: Domain is set for transfer cannot wrap");

            //Mint ERC721 to Owner
            _mint(msg.sender, domain);
            emit Wrapped(msg.sender, domain);
        }
        else if(owner == address(this))
        {
            //Domain allready owned by wrapper Check for changes/renew
            if(_exists(domain)){
                //ERC721 allready exists
                if(owner == ERC721.ownerOf(domain)){
                    //Caller is owner of Domain Renew Domain
                    _etherId.changeDomain(domain, MAX_PROLONG, 0, address(0));

                    //Check that Domain was renewed
                    (,uint newExpires,,,,) = _etherId.getDomain(domain);
                    require(newExpires > (block.number + MAX_PROLONG - 1), "EtherIdWrapper: Error renewing Domain");
                }
                else
                {
                    //Caller Does not own Domain check if expired
                    require(block.number > expires, "EtherIdWrapper: Domain Has not expired");

                    //Domain has expired therefore claimable by caller

                    //Check Wrapper contract still owns Domain
                    require(owner == address(this), "EtherIdWrapper: No longer owns this Domain");

                    //Extend Ownership in Base Contract
                    _etherId.changeDomain(domain, MAX_PROLONG, 0, address(0));

                    //Check that Domain was renewed
                    (,uint newExpires,,,,) = _etherId.getDomain(domain);
                    require(newExpires > (block.number + MAX_PROLONG - 1), "EtherIdWrapper: Error renewing Domain");

                    address wrappedOwner = ERC721.ownerOf(domain);
                    _safeTransfer(wrappedOwner, msg.sender, domain, "");

                    //Check transfer of ERC721
                    address newOwner = ERC721.ownerOf(domain);
                    require(newOwner == msg.sender, "EtherIdWrapper: Error in Transferring Domain");
                }
            }else{
                //ERC721 does not exist but wrapper owns domain (Can Happen if new Domain Transferred to Wrapper when initialised).
                //If Domain is stuck here and ERC721 doesnt exist then domain is claimable

                // Change Domain on base Contract and Create ERC721
                _etherId.changeDomain(domain, MAX_PROLONG, 0, address(0));

                (owner ,expires, price, transfer,, ) = _etherId.getDomain(domain);
                //Check Domain is owned by this contract
                require(owner == address(this), "EtherIdWrapper: Error registering this domain to the wrapper");

                //Check Domain is not expired
                require(expires > block.number, "EtherIdWrapper: Domain has expired cannot wrap");

                //Check Domain has not been listed for sale on base contract (Technically not possible)
                require(price == 0, "EtherIdWrapper: Domain is listed for sale cannot wrap");

                //Check Domain is not set to be transferred (Also Techncally not possible)
                require(transfer == address(0), "EtherIdWrapper: Domain is set for transfer cannot wrap");

                //Wrapped Domain Does not exist. Mint New ERC721
                _mint(msg.sender, domain);
                emit Wrapped(msg.sender, domain);
            }
        }else{
            //Someone Else is Owner of Domain
            require(block.number > expires, "EtherIdWrapper: Domain Has not expired and is owned by someone else");

            //Domain has expired therefore can be claimed and transferred or wrapped

            // Change Domain on base Contract and Create ERC721
            _etherId.changeDomain(domain, MAX_PROLONG, 0, address(0));

            (owner ,expires, price, transfer,, ) = _etherId.getDomain(domain);
            //Check Domain is owned by this contract
            require(owner == address(this), "EtherIdWrapper: Error registering this domain to the wrapper");

            //Check Domain is not expired
            require(expires > block.number, "EtherIdWrapper: Domain has expired cannot wrap");

            //Check Domain has not been listed for sale on base contract (Technically not possible)
            require(price == 0, "EtherIdWrapper: Domain is listed for sale cannot wrap");

            //Check Domain is not set to be transferred (Also Techncally not possible)
            require(transfer == address(0), "EtherIdWrapper: Domain is set for transfer cannot wrap");

            if(_exists(domain)){
                //Domain Allready Wrapped and expired. Transfer to function Caller
                address wrappedOwner = ERC721.ownerOf(domain);
                _safeTransfer(wrappedOwner, msg.sender, domain, "");

                //Check transfer of ERC721
                address newOwner = ERC721.ownerOf(domain);
                require(newOwner == msg.sender, "EtherIdWrapper: Error in Transferring Domain");
            }else{
                //Wrapped Domain Does not exist. Mint New ERC721
                _mint(msg.sender, domain);
                emit Wrapped(msg.sender, domain);
            }
        }
    }

    function changeId(uint domain, uint name, uint value) public{
        //Check NFT Exists
        require(_exists(domain), "EtherIdWrapper: Domain NFT does not exist");

        (address owner,,,,,) = _etherId.getDomain(domain);

        //Check Domain is owned by this contract
        require(owner == address(this), "EtherIdWrapper: This domain is not owned by the Wrapper");

        //Check sender is owner of NFT
        address wrappedOwner = ERC721.ownerOf(domain);
        require(wrappedOwner == _msgSender(), "EtherIdWrapper: You are not the owner");

        _etherId.changeId(domain, name, value);
    }

    /**
        Read Functions
    **/
    function getId(uint domain, uint id) public view returns (uint v, uint next_id, uint prev_id ){
        (v, next_id, prev_id) =  _etherId.getId(domain, id);
    }

    function getDomain(uint domain) public view returns (address owner, uint expires, uint price, address transfer, uint next_domain, uint root_id, bool wrapped ){
        if(_exists(domain)){
            address baseOwner;
            (baseOwner,expires, price, transfer, next_domain, root_id ) = _etherId.getDomain(domain);
            if(baseOwner == address(this)){
                owner = ERC721.ownerOf(domain); 
            }else{
                owner = baseOwner;
            }
            
            wrapped = true;
        }else{
            (owner ,expires, price, transfer, next_domain, root_id ) = _etherId.getDomain(domain);
            wrapped = false;
        }
    }

    /**
        Helper Functions
    **/

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory uri) external onlyOwner {
        baseURI = uri;
    }

    function burnDomain(uint domain) external {
        //For Burning Expired NFT when required to reset must check is fully expired on base contract
        
        //Check Wrapped Domain Exists
        require(_exists(domain), "EtherIdWrapper: Domain NFT Does not exist");

        (address owner, uint expires,,,,) = _etherId.getDomain(domain);

        if(owner == address(this)){
            //Domain is still owned by wrapper contract.

            //Check Domain has Expired
            require(expires < block.number, "EtherIdWrapper: Domain has not expired yet");

            _burn(domain);

            require(!_exists(domain), "EtherIDWrapper: ERC721 Domain has not been burned"); 
        }else{
            //Wrapper Contract no longer owns Domain therefore can be burned.
            _burn(domain);

            require(!_exists(domain), "EtherIDWrapper: ERC721 Domain has not been burned");
        }
    }

    function renewDomain(uint domain) external {
        //Allow anyone to renew a wrapped domain for the max prolong period
        (address owner,,,,,) = _etherId.getDomain(domain);

        //Check Domain is owned by this contract
        require(owner == address(this), "EtherIdWrapper: This domain is not owned by the Wrapper");

        //Renew Domain
        _etherId.changeDomain(domain, MAX_PROLONG, 0, address(0));

        (,uint newExpires,,,,) = _etherId.getDomain(domain);
        require(newExpires > (block.number + MAX_PROLONG - 1), "EtherIdWrapper: Error renewing Domain");
    }
}