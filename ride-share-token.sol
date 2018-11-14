pragma solidity ^0.4.25;

import "github.com/OpenZeppelin/openzeppelin-solidity/contracts/token/ERC721/ERC721Full.sol";
import "github.com/OpenZeppelin/openzeppelin-solidity/contracts/crowdsale/validation/TimedCrowdsale.sol";
import "github.com/OpenZeppelin/openzeppelin-solidity/contracts/ownership/Ownable.sol";

contract RideShareToken is ERC721Full, TimedCrowdsale, Ownable{
    struct Spot{
        string name;
        int32 latitude;
        int32 longitude;
    }
    
    struct Demand{
        bool available;
        uint cost;
        uint reg_date;
        uint est_date;
        uint passengers;
        Spot dept;
        Spot arrv;
    }
    
    mapping(uint=>Demand) internal demands;
    uint private counter;
    
    constructor(
        string name,
        string symbol,
        uint _cost,
        uint _est_date,
        uint _passengers,
        string dept_name,
        int32 dept_lat,
        int32 dept_lon,
        string arrv_name,
        int32 arrv_lat,
        int32 arrv_lon
    )
        ERC721Full(name, symbol)
        TimedCrowdsale(now, _est_date)
        Ownable()
        public
    {
        demands[_getID()] = Demand({
            available:true,
            cost:_cost,
            reg_date:now,
            est_date:_est_date,
            passengers:_passengers,
            dept:Spot({
                name:dept_name,
                latitude:dept_lat,
                longitude:dept_lon
            }),
            arrv:Spot({
                name:arrv_name,
                latitude:arrv_lat,
                longitude:arrv_lon
            })
        });
    }
    
    function _getID() private returns(uint) { return counter++; }
}
