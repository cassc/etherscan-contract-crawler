// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


import "erc-payable-token/contracts/token/ERC1363/ERC1363.sol";
import "../common/AccessiblePlusCommon.sol";


contract DOC is ERC1363, AccessiblePlusCommon {
    bytes32 public DOMAIN_SEPARATOR;
    mapping(address => uint256) public nonces;


    /// @dev Value is equal to keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant PERMIT_TYPEHASH =
        0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 initialSupply,
        address _owner
    ) ERC20(_name, _symbol) {
        _mint(_owner, initialSupply);

        uint256 chainId;
        assembly {
            chainId := chainid()
        }

        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                // keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)')
                0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f,
                keccak256(bytes(_name)),
                keccak256(bytes(_symbol)),
                chainId,
                address(this)
            )
        );

        _setRoleAdmin(ADMIN_ROLE, ADMIN_ROLE);
        _setRoleAdmin(BURNER_ROLE, ADMIN_ROLE);
        _setRoleAdmin(MINTER_ROLE, ADMIN_ROLE);

        _setupRole(ADMIN_ROLE, _owner);
        _setupRole(BURNER_ROLE, _owner);
        _setupRole(MINTER_ROLE, _owner);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1363, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
    
    function mint(address account, uint256 amount) 
        external
        onlyMinter
        returns (bool)
    {
        _mint(account,amount);
        return true;
    }

    function burn(address account, uint256 amount) 
        external 
        onlyBurner
        returns (bool)
    {
        _burn(account,amount);
        return true;
    }

    /// @dev Authorizes the owner's token to be used by the spender as much as the value.
    /// @dev The signature must have the owner's signature.
    /// @param owner the token's owner
    /// @param spender the account that spend owner's token
    /// @param value the amount to be approve to spend
    /// @param deadline the deadline that valid the owner's signature
    /// @param v the owner's signature - v
    /// @param r the owner's signature - r
    /// @param s the owner's signature - s
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        require(deadline >= block.timestamp, "permit EXPIRED");

        bytes32 digest =
            hashPermit(owner, spender, value, deadline, nonces[owner]++);

        require(owner != spender, "approval to current owner");

        // if (Address.isContract(owner)) {
        //     require(IERC1271(owner).isValidSignature(digest, abi.encodePacked(r, s, v)) == 0x1626ba7e, 'Unauthorized');
        // } else {
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress != address(0), "Invalid signature");
        require(recoveredAddress == owner, "Unauthorized");
        // }
        _approve(owner, spender, value);
    }

    /// @dev verify the signature
    /// @param owner the token's owner
    /// @param spender the account that spend owner's token
    /// @param value the amount to be approve to spend
    /// @param deadline the deadline that valid the owner's signature
    /// @param _nounce the _nounce
    /// @param sigR the owner's signature - r
    /// @param sigS the owner's signature - s
    /// @param sigV the owner's signature - v
    function verify(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint256 _nounce,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) external view returns (bool) {
        return
            owner ==
            ecrecover(
                hashPermit(owner, spender, value, deadline, _nounce),
                sigV,
                sigR,
                sigS
            );
    }

    /// @dev the hash of Permit
    /// @param owner the token's owner
    /// @param spender the account that spend owner's token
    /// @param value the amount to be approve to spend
    /// @param deadline the deadline that valid the owner's signature
    /// @param _nounce the _nounce
    function hashPermit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint256 _nounce
    ) public view returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR,
                    keccak256(
                        abi.encode(
                            PERMIT_TYPEHASH,
                            owner,
                            spender,
                            value,
                            _nounce,
                            deadline
                        )
                    )
                )
            );
    }


}