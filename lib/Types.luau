-- Base type
type File = {
    Name: string,
    Start: () -> (),
    Init: () -> (),
}

export type Service = File & {
    ServiceId: number,
}

export type Controller = File & {
    Priority: number,
}

export type Manager = File & {
    Priority: number,
}

export type Packet = {
    Recieve: any,
    Data: any,
}

return nil