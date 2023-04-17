// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./Master.sol";

//Imports for swaping
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "./IUniswapV2Router02.sol";

contract nuevaTienda is Ownable {
    //Trabajar con las monedas en los intercambios
    IERC20 amt;
    IERC20 monedaPago;
    IERC20 usdt;

    //Para poder cobrar
    IERC20 btcb;
    Master master;

    //Pancake swap integrations
    IUniswapV2Router02 router;
    IUniswapV2Pair pair;
    address[] path;

    address adminWallet;
    address addrMaster = 0x13e98112e1c67DbE684adf3Aeb1C871F1fe6D1Ac;

    address addrAmt = 0x6Ae0A238a6f51Df8eEe084B1756A54dD8a8E85d3;
    address addrUsdt = 0x55d398326f99059fF775485246999027B3197955;
    address addrBtcb = 0x7130d2A12B9BCbFAe4f2634d864A1Ee1Ce3Ead9c;

    uint256 precio; // AMT equivalen a 1000 USD
    address addrRouter = 0x10ED43C718714eb63d5aA57B78B54704E256024E;

    constructor(address _adminWallet, uint256 _precio) {
        amt = IERC20(addrAmt);
        usdt = IERC20(addrUsdt);
        btcb = IERC20(addrBtcb);
        adminWallet = _adminWallet;

        precio = _precio; // CANTIDAD DE AMT QUE EQUIVALEN A 1000 USDT (Son tantos si tenemos margen con los decimales)
        router = IUniswapV2Router02(addrRouter);

        master = Master(addrMaster);
    }

    function buy(uint256 amountMonedaPago, address addrMonedaPago) public {
        // El contrato necesita el monto con el que la persona va a pagar y el addr de esa moneda. X
        // Cargo la moneda. X
        // Con ese monto: 1 - Voy al router y le pregunto cuando consigo de USDT. X
        //                2 - Voy al router y swapeo por USDT (indicandole el minimo con paso anterior). X
        // El contrato recibe USDT en la transaccion. X
        // Consulto el balance en USDT del contrato para tener el monto exacto.X
        // Le envio al admin los USDT.
        // Le envio al usuario la cantidad equivalente.
        monedaPago = IERC20(addrMonedaPago);
        require(amountMonedaPago > 10, "Ponga un numero mas grande");
        require(
            monedaPago.balanceOf(msg.sender) >= amountMonedaPago,
            "NO POSEE SUFICIENTE Moneda de pago"
        );

        path = [addrMonedaPago, addrUsdt];

        uint256[] memory returnPancake = router.getAmountsOut(
            amountMonedaPago,
            path
        );

        router.swapExactTokensForTokens(
            amountMonedaPago,
            (returnPancake[1] * 90) / 100,
            path,
            address(this),
            block.timestamp + 600
        );

        uint256 balanceUsdt = usdt.balanceOf(address(this));

        usdt.transfer(adminWallet, balanceUsdt);
        amt.transfer(msg.sender, (balanceUsdt * precio));
    }

    function vaciarTienda() public onlyOwner {
        uint256 cantidadARetirar = amt.balanceOf(address(this));
        amt.transfer(msg.sender, cantidadARetirar);
    }

    function vaciarMonedaEspecifica(address addr) public onlyOwner {
        IERC20 moneda;
        moneda = IERC20(addr);

        uint256 cantidadARetirar = moneda.balanceOf(address(this));
        moneda.transfer(msg.sender, cantidadARetirar);
    }

    function charge(uint256 snapId) public onlyOwner {
        uint256 amount = master.charge(snapId);
        btcb.transfer(msg.sender, amount);
    }
}